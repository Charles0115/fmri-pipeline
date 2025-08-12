# Functional MRI Pipeline

This is the documentation of functional MRI pipeline for monkeys in Dr. Shmuel's lab at McGill Neuroscience. 

## Description

An in-depth paragraph about your project and overview of use.

## Getting Started

### System

* I'm using Windows 11 with Ubuntu 24.04 sub system (WSL), thus some software are installed on Windows. All software used in the pipeline are available on all major systems (macOS, Linux). 
* If you are using Windows, you do need a Linux WSL. Tutorial is available in the Tools section. 

### Tools

* AFNI: https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/background_install/install_instructs/index.html
  * AFNI has a complete tutorial about setting up WSL. https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/background_install/install_instructs/steps_windows10.html
  * Please follow the instruction carefully and make sure that AFNI is working properly on your computer!
* FSL: https://fsl.fmrib.ox.ac.uk/fsl/docs/#/install/index
* MatLab: https://www.mathworks.com/help/install/ug/install-products-with-internet-connection.html
  * An additional package called MonkeyLogic is need. Link: https://monkeylogic.nimh.nih.gov/
* Python3: https://www.python.org/downloads/

### Data

There are two types of data, one being bhv files and another one being fMRI data files. 

* bhv files contain experimental parameters and actions, which are used for plotting graphs and generating 1D timing files. To obtain the bhv files, email whomever did the experiment. 
* fMRI data files are MRI images, which we mainly process. To obtain the data files, follow the steps below. 
  1. You need to have a <u>bic.mni.mcgill.ca</u> account. If you don’t have it, ask lab members or Amir. 
  2. Open your terminal and login using ```ssh username@login.bic.mni.mcgill.ca```
  3. Look for the data using ```find_mri date``` where date looks like this "20250708". It will return the path to the data folder. There are two data folders. 
  4. Once the data is found, you need to claim the data by using ```find_mri -claim /data/dicom/minc/pip_XXXXX``` and ```find_mri -claim /data/dicom/pip_XXXXX```. 
  5. Use Filezilla or WinSCP to download the data from BIC server. 


### Installing

* How/where to download your program
* Any modifications needed to be made to files/folders

### Executing program

* How to run the program
* Step-by-step bullets
```
code blocks for commands
```

## Pipeline

### <u>MatLab</u>


### <u>Python</u>

### Set up Virtual Environment
Virtual Environment is beneficial because you can install packages locally, for this project. If you use IDEs like PyCharm, there's a virtual environment already setup (.venv). Otherwise, you have to create the virtual environment yourself. In case you don't know how, here are the steps. 
1. ```python3 -m venv .venv```
2. To activate: ```source .venv/bin/activate```
3. To deactivate: ```deactivate```

### Install necessary packages

Install the necessary packages. There is a requirement.txt in the project. You can install all the packages at once by typing ```pip install -r requirements.txt```

### plot_graphs.py

plot_graphs.py is used to generate graphs. I suggest reading through the code briefly to get a general idea of what’s going on.  There are lots of comments and instructions to help you understand. You don’t have to understand every piece of code, unless the requirements have been changed and you need to do modifications. 

Currently, the requirement is to generate a signal graph that has everything in it, which means it includes start & end, stimulus & baseline, reward & no reward, eye position of the monkey, etc. However, if you want to have individual graphs, there are such methods like plot_discrete_graph for you to use. The issue is that they are outdated and not guaranteed to work properly. 

To run this: ```python plot_graphs.py```

### eyepos-threshold-checker.py

eyepos-threshold-checker.py is used to create an outlier 1D binary file based on the eye position. It has two methods, mean and percentage. For mean, specify the mean threshold and standard deviation threshold. If the data is less than both thresholds, 1 is written, otherwise 0. For percentage, you specify a percentage threshold and the fixation. The script calculates the percentage of good rate (data entries that are less than the fixation). If the rate is higher than the threshold, 1 is written, otherwise 0. 

To run this: ```python eyepos-threshold-checker.py```

## Help

Any advise for common problems or issues.
```
command to run if program contains helper info
```

## Author

Charles Liu

Email: <u>peiyong.liu@mail.mcgill.ca</u>

## Version History

* 0.2
    * Various bug fixes and optimizations
    * See [commit change]() or See [release history]()
* 0.1
    * Initial Release

## License

This project is licensed under the [NAME HERE] License - see the LICENSE.md file for details

## Acknowledgments

Inspiration, code snippets, etc.
* [awesome-readme](https://github.com/matiassingers/awesome-readme)
* [PurpleBooth](https://gist.github.com/PurpleBooth/109311bb0361f32d87a2)
* [dbader](https://github.com/dbader/readme-template)
* [zenorocha](https://gist.github.com/zenorocha/4526327)
* [fvcproductions](https://gist.github.com/fvcproductions/1bfc2d4aecb01a834b46)
