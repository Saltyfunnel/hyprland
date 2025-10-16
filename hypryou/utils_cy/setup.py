from setuptools import setup
from Cython.Build import cythonize

setup(
    name="utils_cy",
    ext_modules=cythonize(
        ["utils_cy/levenshtein.pyx", "utils_cy/helpers.pyx"],
        language_level=3
    )
)
