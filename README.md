
>
> ### Direct Installation
>
> You can now easily install the config directly without cloning the repository. Just copy and paste the command bellow in your terminal and run it. Before that, make sure to install `curl`. Install it using pacman, dnf or zypper.

```
bash <(curl -s https://raw.githubusercontent.com/shell-ninja/hyprconf-install/main/direct_run.sh)
```

> [!NOTE]
>
> ### Manusally Installation

> - Clone this repository:

```
git clone --depth=1 https://github.com/shell-ninja/hyprconf-install.git
```

> - Now cd into hyprconf-install directory and run this command.:

```
cd ~/hyprconf-install
chmod +x install.sh
./install.sh
```

> [!TIP]
> You can follow this part while installing. Here are the prompts that will be askes while installing.

### Prompts

<details close>
<summary>Installation Prompts</summary>

When you run the script, it will ask you some prompts. You can choose according to your need. You can choose multiple options using the space bar.

<img src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/install/1.png?raw=true" /> <br>

</details>

<details close>
<summary>Install Shell</summary>

You can choose which shell you want to install (only one). Install customized [zsh](https://github.com/shell-ninja/Zsh) or `fish`. If you choose `setup_bash`, it will Set up my configured [bash](https://github.com/shell-ninja/Bash).

<img src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/install/2.png?raw=true" /> <br>

</details>

<details close>
<summary>Install Browser</summary>

You have the freedom to choose a web browser. I you don't want to install any, you can simply skip it.

<img src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/install/3.png?raw=true" />
<br>
</details>

<details close>
<summary>Install Version</summary>

Now you can choose from the `Stable` and `Roling Release` version

<img src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/install/version.png?raw=true" />
<br>
</details>

<details close>
<summary>keyboard layout and variant</summary>
<br>

The default keyboard layout will be `us`. If it's not your preferred keyboard layout, you can pick your one. <br>
Also, you can choose the keyboard variant, or keep it empty.

- Keyboard Layout
<p align="center">
<br>
    <img width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/install/kb_layout.png?raw=true" />
    <img width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/install/kb_layout_select.png?raw=true" />
</p>

- Keyboar Variant
<p align="center">
<br>
    <img width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/install/kb_variant.png?raw=true" />
    <img width="49%" src="https://github.com/shell-ninja/Screen-Shots/blob/main/hyprconf/install/kb_variant_select.png?raw=true" />
</p>
</details>

<br>

<a id="keyboards"></a>

<div align="right">
  <br>
  <a href="#top"><kbd> <br> 🡅 <br> </kbd></a>
</div>

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=KEYBOARD-SHORTCUTS" width="450"/>

> [!IMPORTANT]
>
> After installation, just press the `SUPER + Shift + h`. It will show you all the keybinds.

<br>

<a id="contrib"></a>

<div align="right">
  <br>
  <a href="#top"><kbd> <br> 🡅 <br> </kbd></a>
</div>

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=CONTRIBUTING" width="450"/>

<h4>
If you want to add your ideas in this project, just do some steps.
</h4>

1. Fork this repository. Make sure to uncheck the `Copy the main branch only`. This will also copy other branches ( if available ).
2. Now clone the forked repository in you machine. <br> Example command:

```
git clone --depth=1 https://github.com/your_user_name/hyprconf.git
```

3. Create a branch by your user_name. <br> Example command:

```
git checkout -b your_user_name
```

4. Now add your ideas and commit to github. <br> Make sure to commit with a detailed test message. For example:

```
git commit -m "fix: Fixed a but in the "example.sh script"
```

```
git commit -m "add: Added this feature. This will happen if the user do this."
```

```
git commit -m "delete: Deleted this. It was creating this example problem"
```

4. While pushing the new commits, make sure to push it to your branch. <br> For example:

```
git push origin your_branch_name
```

5. Now you can create a pull request in the main repository.<br> But make sure to create the pull request in the `development` branch, no the `main` branch.

### Thats all about contributing.

<br>

## <img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=90EE90&vCenter=true&width=435&height=25&lines=THANKS" width="450"/>

I would like to thank [JaKooLit](https://github.com/JaKooLit). I was inspired from his Hyprland installation scripts and prepared my script. I took and modified some of his scripts and used here.
