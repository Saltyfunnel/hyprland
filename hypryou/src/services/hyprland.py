import asyncio
from enum import Enum
import os
from asyncio import StreamReader, StreamWriter
from utils.ref import Ref, Computed
from utils.logger import logger
import typing as t
import json
from utils.service import Signals, AsyncService
from repository import gio, gtk, gdk
from config import Settings

active_workspace = Ref(0, name="workspace", delayed_init=True)
active_layout = Ref("en", name="active_layout", delayed_init=True)
active_monitor_name = Ref[str](
    "", name="active_monitor_name"
)

show_layout = Ref(False, name="show_layout", delayed_init=True)
night_light = Ref(False, name="night_light", delayed_init=True)

workspace_monitors = Ref[dict[int, int]](
    {},
    name="workspace_monitors"
)
monitor_ids = Ref[dict[str, int]](
    {},
    name="monitor_ids"
)
workspace_ids = Computed[set[int]](
    set(),
    lambda: set(workspace_monitors.value.keys()),
    name="workspace_ids",
    refs={workspace_monitors}
)
clients = Ref[dict[str, "Client"]](
    {},
    name="hyprland_clients"
)
active_monitor_id = Computed[int](
    -1,
    lambda: monitor_ids.value.get(active_monitor_name.value, -1),
    name="active_monitor_id",
    refs={monitor_ids, active_monitor_name}
)
active_client = Ref[dict[int, "Client | None"]](
    {},
    name="active_client",
)


type HyprlandQueryType = t.Literal[
    "activewindow",
    "activeworkspace",
    "clients",
    "devices",
    "dispatch",
    "getoption",
    "hyprlandversion",
    "junct",
    "layers",
    "monitors",
    "splash",
    "workspaces"
]


ClientWorkspace = t.TypedDict(
    "ClientWorkspace",
    {
        "id": int,
        "name": str
    }
)

ClientDict = t.TypedDict(
    "ClientDict",
    {
        "address": str,
        "mapped": bool,
        "hidden": bool,
        "at": list[int],
        "size": list[int],
        "workspace": ClientWorkspace,
        "floating": bool,
        "pseudo": bool,
        "monitor": int,
        "class": str,
        "title": str,
        "initialClass": str,
        "initialTitle": str,
        "pid": int,
        "xwayland": bool,
        "pinned": bool,
        "fullscreen": int,
        "fullscreenClient": int,
        "grouped": list[str],
        "tags": list[t.Any],
        "swallowing": str,
        "focusHistoryId": int,
        "inhibitingIdle": bool,
        "xdgTag": str,
        "xdgDescription": str,
    }
)


class MonitorDict(t.TypedDict):
    id: int
    name: str
    description: str
    make: str
    model: str
    serial: str
    width: int
    height: int
    refreshRate: float
    x: int
    y: int
    activeWorkspace: ClientWorkspace
    specialWorkspace: ClientWorkspace
    reversed: list[int]
    scale: float
    transform: int
    focused: bool
    dpmsStatus: bool
    vrr: bool
    solitary: str
    activelyTearing: bool
    directScanoutTo: str
    disabled: bool
    currentFormat: str
    mirrorOf: str
    availableModes: list[str]


class Client(Signals):
    def __init__(self, client: ClientDict) -> None:
        super().__init__()
        self._data = client

    def notify_changed(self) -> None:
        # I couldn't find any better way to do that without refs, sadly
        self.notify("changed")
        if active_client.value.get(self.monitor) is self:
            active_client.notify_signal("changed", active_client.value)

    def sync(self) -> None:
        async def async_task() -> None:
            data = await get_client_dict_by_address(self.address)
            if data is None:
                await clients_full_sync()
            else:
                self._data = data
                self.notify_changed()

        asyncio.create_task(async_task())

    def get_icon(self) -> gtk.IconPaintable | None:
        original_app_id = self.initial_class
        possible_ids = [
            original_app_id.replace(" ", "-").lower(),
            original_app_id.lower(),
            str(original_app_id),
            f"{original_app_id}.desktop",
        ]

        desktop_file: gio.AppInfo | None = None
        for app_id_candidate in possible_ids:
            if not app_id_candidate:
                continue
            try:
                desktop_file = gio.DesktopAppInfo.new(app_id_candidate)
            except TypeError:
                continue
            if desktop_file:
                break

        if not desktop_file:
            lower_original = original_app_id.lower()
            for info in gio.AppInfo.get_all():
                id = (info.get_id() or "").lower()
                if (
                    id
                    and (id.startswith(lower_original)
                         or id.endswith(lower_original))
                ):
                    desktop_file = info
                    break

        if not desktop_file:
            return None

        icon = desktop_file.get_icon()
        icon_name = icon.to_string() if icon else original_app_id.lower()
        if icon_name is None:
            return None

        display = gdk.Display.get_default()
        theme = gtk.IconTheme.get_for_display(display)

        icon_info = theme.lookup_icon(
            icon_name,
            None,
            48,
            1,
            gtk.TextDirection.RTL,
            gtk.IconLookupFlags.FORCE_SYMBOLIC,
        )
        return icon_info

    @property
    def workspace_id(self) -> int:
        return self._data["workspace"]["id"]

    @property
    def workspace_name(self) -> str:
        return self._data["workspace"]["name"]

    @property
    def address(self) -> str:
        return self._data["address"]

    @property
    def mapped(self) -> bool:
        return self._data["mapped"]

    @property
    def hidden(self) -> bool:
        return self._data["hidden"]

    @property
    def at(self) -> tuple[int, int]:
        return (self._data["at"][0], self._data["at"][1])

    @property
    def size(self) -> tuple[int, int]:
        return (self._data["size"][0], self._data["size"][1])

    @property
    def workspace(self) -> ClientWorkspace:
        return self._data["workspace"]

    @property
    def floating(self) -> bool:
        return self._data["floating"]

    @property
    def pseudo(self) -> bool:
        return self._data["pseudo"]

    @property
    def monitor(self) -> int:
        return workspace_monitors.value.get(self.workspace_id, -1)

    @property
    def class_(self) -> str:
        return self._data["class"]

    @property
    def title(self) -> str:
        return self._data["title"]

    @property
    def initial_class(self) -> str:
        return self._data["initialClass"]

    @property
    def initial_title(self) -> str:
        return self._data["initialTitle"]

    @property
    def pid(self) -> int:
        return self._data["pid"]

    @property
    def xwayland(self) -> bool:
        return self._data["xwayland"]

    @property
    def pinned(self) -> bool:
        return self._data["pinned"]

    @property
    def fullscreen(self) -> bool:
        return int(self._data["fullscreen"]) >= 2

    @property
    def maximized(self) -> bool:
        return int(self._data["fullscreen"]) in (1, 3)

    @property
    def fullscreen_client(self) -> int:
        raise NotImplementedError("Not synced")

    @property
    def grouped(self) -> list[str]:
        raise NotImplementedError("Not synced")

    @property
    def tags(self) -> list[t.Any]:
        return self._data["tags"]

    @property
    def swallowing(self) -> str:
        return self._data["swallowing"]

    @property
    def focus_history_id(self) -> int:
        return self._data["focusHistoryId"]

    @property
    def inhibiting_idle(self) -> bool:
        raise NotImplementedError("Not synced")

    @property
    def xdg_tag(self) -> str:
        return self._data["xdgTag"]

    @property
    def xdg_description(self) -> str:
        return self._data["xdgDescription"]


class SocketType(int, Enum):
    HYPRLAND = 0
    HYPRSUNSET = 1


class HyprlandClient(Signals):
    def __init__(self) -> None:
        super().__init__()
        self.version = ""
        runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "/run/user/1000")
        instance = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]

        instance_path = f"{runtime_dir}/hypr/{instance}"
        self.socket_path_events = f"{instance_path}/.socket2.sock"
        self.sockets = {
            SocketType.HYPRLAND: f"{instance_path}/.socket.sock",
            SocketType.HYPRSUNSET: f"{instance_path}/.hyprsunset.sock"
        }

        self.reader: StreamReader | None = None
        self.writer: StreamWriter | None = None

    async def connect(self) -> None:
        self.reader, self.writer = await asyncio.open_unix_connection(
            self.socket_path_events
        )
        while True:
            line = await self.reader.readline()
            if not line:
                break
            decoded = line.decode("utf-8", errors="replace").rstrip("\n")
            if ">>" not in decoded:
                continue
            event, data = decoded.split(">>", 1)
            args: list[str] = data.split(",") if data else []
            self.notify(event, *args)

    async def raw(
        self,
        command: str,
        socket_type: SocketType = SocketType.HYPRLAND,
        timeout: float = 2.0,
    ) -> str:
        reader, writer = await asyncio.open_unix_connection(
            self.sockets[socket_type]
        )
        writer.write(command.encode("utf-8"))
        writer.write_eof()
        await writer.drain()
        data = b""
        try:
            data = await asyncio.wait_for(
                reader.read(),
                timeout=timeout
            )
        except asyncio.TimeoutError as e:
            writer.close()
            await writer.wait_closed()
            logger.error(
                f"Timeout waiting for response to command: {command!r}",
                exc_info=e
            )
            return ""
        finally:
            if not writer.is_closing():
                writer.close()
                await writer.wait_closed()

        writer.close()
        await writer.wait_closed()
        return data.decode().strip()

    async def query(self, command: HyprlandQueryType | str) -> t.Any:
        raw_result = await self.raw(f"j/{command}")
        try:
            return json.loads(raw_result)
        except json.JSONDecodeError:
            return raw_result

    async def dispatch(self, subcommand: str) -> str:
        return await self.raw(f"dispatch {subcommand}")


client: HyprlandClient


class EventCallbacks:
    @staticmethod
    def on_workspacev2(
        new_workspace_id: str,
        new_workspace_name: str
    ) -> None:
        active_workspace.value = int(new_workspace_id)

    @staticmethod
    def on_focusedmonv2(
        new_monitor_name: str,
        new_workspace_id: str
    ) -> None:
        active_workspace.value = int(new_workspace_id)
        active_monitor_name.value = new_monitor_name

    @staticmethod
    def on_activelayout(
        keyboard_name: str,
        layout_name: str
    ) -> None:
        if layout_name != active_layout.value:
            show_layout.value = True
        active_layout.value = layout_name

    @staticmethod
    def on_createworkspacev2(
        workspace_id: str,
        workspace_name: str
    ) -> None:
        workspace_monitors.value[int(workspace_id)] = active_monitor_id.value

    @staticmethod
    def on_destroyworkspacev2(
        workspace_id: str,
        workspace_name: str
    ) -> None:
        if int(workspace_id) in workspace_monitors.value:
            del workspace_monitors.value[int(workspace_id)]

    @staticmethod
    def on_openwindow(
        window_address: str,
        workspace_name: str,
        window_class: str,
        *_window_title: str
    ) -> None:
        async def async_task() -> None:
            client = await get_client_by_address(window_address)
            if client is None:
                await clients_full_sync()
            else:
                clients.value[window_address] = client

        asyncio.create_task(async_task())

    @staticmethod
    def on_movewindowv2(
        window_address: str,
        workspace_id: str,
        workspace_name: str
    ) -> None:
        if window_address in clients.value.keys():
            _client = clients.value[window_address]
            _client._data["workspace"]["id"] = int(workspace_id)
            _client._data["workspace"]["name"] = workspace_name
            _client.notify_changed()
        else:
            asyncio.create_task(clients_full_sync())

    @staticmethod
    def on_windowtitlev2(
        window_address: str,
        *_window_title: str
    ) -> None:
        window_title = ",".join(_window_title)
        if window_address in clients.value.keys():
            _client = clients.value[window_address]
            _client._data["title"] = window_title
            _client.notify_changed()
        else:
            # NOTE: I would use clients_full_sync() here
            # but Hyprland can sometimes send this event
            # before openwindow event
            pass

    @staticmethod
    def on_pin(
        window_address: str,
        pin_state: bool
    ) -> None:
        if window_address in clients.value.keys():
            _client = clients.value[window_address]
            _client._data["pinned"] = pin_state
            _client.notify_changed()
        else:
            asyncio.create_task(clients_full_sync())

    @staticmethod
    def on_closewindow(
        window_address: str
    ) -> None:
        if window_address in clients.value.keys():
            client = clients.value.pop(window_address)
            for monitor_id, _client in active_client.value.items():
                if _client is client:
                    del active_client.value[monitor_id]
                    break
        else:
            asyncio.create_task(clients_full_sync())

    @staticmethod
    def on_activewindowv2(
        window_address: str | None = None
    ) -> None:
        if window_address and window_address not in clients.value.keys():
            asyncio.create_task(clients_full_sync())
        elif window_address is None:
            active_client.value[active_monitor_id.value] = None
        else:
            client = clients.value[window_address]
            active_client.value[client.monitor] = client

    @staticmethod
    def on_fullscreen(
        state: str
    ) -> None:
        # Now state gives only 0/1
        # I made a discussions on hyprland's github page
        # https://github.com/hyprwm/Hyprland/discussions/11894
        # Hopefully they will implement what I asked for
        # So I will be able optimize this code
        # But now, I have to just do full sync
        asyncio.create_task(clients_full_sync())

    @staticmethod
    def on_moveworkspacev2(
        workspace_id: str,
        workspace_name: str,
        *monitor_name: str
    ) -> None:
        try:
            workspace_monitors.value[int(workspace_id)] = (
                monitor_ids.value[",".join(monitor_name)]
            )
        except KeyError:
            asyncio.create_task(clients_full_sync())

    @staticmethod
    def on_monitoraddedv2(
        monitor_id: str,
        monitor_name: str,
        *monitor_description: str
    ) -> None:
        monitor_ids.value[monitor_name] = int(monitor_id)

    @staticmethod
    def on_monitorremovedv2(
        _monitor_id: str,
        monitor_name: str,
        *monitor_description: str
    ) -> None:
        try:
            if monitor_name in monitor_ids.value:
                monitor_id = monitor_ids.value[monitor_name]
                del active_client.value[monitor_id]
                del monitor_ids.value[monitor_name]
        except KeyError:
            asyncio.create_task(clients_full_sync())


class Keyboard(t.TypedDict):
    address: str
    name: str
    rules: str
    model: str
    layout: str
    variant: str
    options: str
    active_keymap: str
    capsLock: bool
    numLock: bool
    main: bool


def get_layouts(keyboard: Keyboard) -> list[str]:
    return keyboard["layout"].strip().strip(",").split(",")


async def get_active_layout(client: HyprlandClient) -> tuple[bool, str]:
    show_layout = False
    devices = await client.query("devices")
    keyboards: list[Keyboard] = devices.get("keyboards")
    assert isinstance(keyboards, list), (
        "Keyboards type isn't correct! " +
        f"{type(keyboards)} != list"
    )

    if not keyboards:
        return False, "English (US)"

    for keyboard in keyboards:
        if keyboard["main"]:
            show_layout = len(get_layouts(keyboard)) > 1
            return show_layout, keyboard["active_keymap"]

    keyboard = keyboards[-1]
    show_layout = len(get_layouts(keyboard)) > 1
    return show_layout, keyboard["active_keymap"]


async def get_active_workspaces(client: HyprlandClient) -> dict[int, int]:
    workspaces = await client.query("workspaces")
    assert isinstance(workspaces, list), (
        "Workspaces has to be list. " +
        f"{type(workspaces)} != list"
    )

    workspace_monitors = {
        int(object["id"]): int(object["monitorID"])
        for object in workspaces
    }
    return workspace_monitors


def change_night_light(value: bool) -> None:
    Settings().set("hyprsunset.value", value)
    if value:
        temperature = Settings().get("hyprsunset.temperature")
        asyncio.create_task(
            client.raw(
                f"temperature {temperature}",
                SocketType.HYPRSUNSET, 2.0
            )
        )
    else:
        asyncio.create_task(
            client.raw("temperature 6500", SocketType.HYPRSUNSET, 2.0)
        )


async def get_client_by_address(addr: str) -> Client | None:
    output: list[ClientDict] = await client.query("clients")
    if not addr.startswith("0x"):
        addr = "0x" + addr

    for _client in output:
        if _client["address"] == addr:
            return Client(_client)
    return None


async def get_client_dict_by_address(addr: str) -> ClientDict | None:
    output: list[ClientDict] = await client.query("clients")

    for _client in output:
        if _client["address"] == addr:
            return _client
    return None


async def clients_full_sync() -> None:
    output: list[ClientDict] = await client.query("clients")
    addresses: list[str] = []

    _monitors = await get_monitors()
    for monitor in _monitors:
        monitor_ids.value[monitor["name"]] = monitor["id"]

    for _client in output:
        address = _client["address"].lstrip("0x")
        if address in clients.value:
            clients.value[address]._data = _client
            clients.value[address].notify_changed()
        else:
            clients.value[address] = Client(_client)
        addresses.append(address)

    for client_address in set(clients.value.keys()):
        if client_address not in addresses:
            clients.value.pop(client_address)

    _active_window = await client.query("activewindow")
    if _active_window:
        _active_window_address = (
            str(_active_window["address"]).removeprefix("0x")
        )
        if _active_window_address in clients.value.keys():
            _client = clients.value[_active_window_address]
            active_client.value[_client.monitor] = _client

    clients.notify_signal("synced", clients.value)


def acquire_clients() -> None:
    asyncio.create_task(clients_full_sync())


def release_clients() -> None:
    pass


async def get_monitors() -> list[MonitorDict]:
    return t.cast(list[MonitorDict], await client.query("monitors all"))


async def init() -> None:
    global client
    client = HyprlandClient()

    version: dict[str, str] = await client.query("version")
    client.version = f"{version["version"]} ({version["commit"][:6]})"

    if __debug__:
        logger.debug("Loading hyprland variables")

    _active_workspace = await client.query("activeworkspace")
    active_workspace.value = int(_active_workspace["id"])
    active_monitor_name.value = str(_active_workspace["monitor"])
    active_workspace.ready()

    show_layout.value, active_layout.value = await get_active_layout(client)
    active_layout.ready()
    show_layout.ready()

    _active_workspaces = await get_active_workspaces(client)
    workspace_monitors.value = _active_workspaces

    await clients_full_sync()

    try:
        _temperature = await client.raw(
            "temperature", SocketType.HYPRSUNSET, 2.0
        )
        if not _temperature.isdigit():
            logger.error("Invalid answer from hyprsunset: %s", _temperature)
        else:
            hyprsunset_settings = Settings().get_view_for("hyprsunset")
            if hyprsunset_settings.get("remember"):
                last_state = bool(hyprsunset_settings.get("value"))
                night_light.value = last_state
            else:
                night_light.value = int(_temperature) < 6000

            night_light.ready()

            change_night_light(night_light.value)
            night_light.watch(change_night_light)
    except (ConnectionRefusedError, FileNotFoundError) as e:
        logger.error("Couldn't connect to hyprsunset", exc_info=e)

    if __debug__:
        logger.debug("Creating hyprland watchers")
    for attr in dir(EventCallbacks):
        if attr.startswith("on_"):
            callback = getattr(EventCallbacks, attr)
            if callable(callback):
                event = attr[3:]
                client.watch(event, callback)


class HyprlandService(AsyncService):
    async def app_init(self) -> None:
        await init()

    async def start(self) -> None:
        global client
        if __debug__:
            logger.debug("Connecting to hyprland")
        await client.connect()
