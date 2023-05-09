import setuptools
import versioneer

with open("README.md", "r") as fh:
    long_description = fh.read()
with open("requirements.txt", "r") as fh:
    requirements = [line.strip() for line in fh]

setuptools.setup(
    name="ibrp",
    version="1.0.0",
    cmdclass=versioneer.get_version(),
    author="Will McKinley",
    author_email="will.mckinley@solo.io",
    description="A Python library to parse istioctl bug reports.",
    long_description=long_description,
    long_description_content_type="text/x-md",
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
    install_requires=requirements,
)