# Concussion Adaptation Project
By Devon Lantagne\
IRB: Marquette University, HR-3233

## Project Description

In this longitudinal study, we had health and recently-concussed subjects perform out-and-back reaches using a robotic manipulandum. Subjects performed many reach trials (saved as MATLAB .mat files). Each subject attended multiple visits (sessions).

This codebase uses the object-oriented programming style.

## Important Files
- `SetThisPath.m` Run this in MATLAB to automatically configure your MATLAB path to find the project's helper functions.
- `Scripts/Classes/RobotTrial4.m` Contains the class definition of a reach trial. Contains all within-trial data and methods.
- `Scripts/Classes/@RobotResults2` Contains the class definition of an experimental session (a collection of trials). Use for within-session analyses.

## Data and File Structure
The general structure of the project is as follows.\
- `Scripts` holds all code of the project and is synced to GitHub.
- `Data` holds all raw subject data and processed subject data. Also holds results.
```
.
├── Scripts/
│   ├── Classes/
│   ├── Helper Functions/
│   ├── Processing/
│   └── OtherScripts...
└── Data/
    ├── SubC001/
    │   ├── Session1/
    │   │   ├── Robot/
    │   │   │   └── trial .mat files...
    │   │   ├── RR2.mat
    │   │   └── RR2_Auto.mat
    │   ├── Session2/
    │   ├── Session3/
    │   ├── Session4/
    │   └── RRs.mat
    ├── SubC002
    ├── SubN001
    └── ...
```
### Configuring the `Data` folder
The `Data` folder will need to be connected to a NAS or a local folder. Inside `Data` is a folder for each test subject. Within each subject folder are folders for each experimental session `Session1`, `Session2` etc. Within each session folder is a `Robot` folder which contains raw data from the collection device.

Intermediate data processing are stored in .mat files of the respective folder. For example, a collection of processed trials for subject C001's first experimental session would be in the `Data/SubC001/Session1/RR2.mat` file. A file containing all their sessions would be in the `Data/SubC001/RRs.mat`.

## Commonly used abbreviations:
- `RT4s` "Robot Trial version 4 objects" These are the MATLAB objects containing individual trial data. Often used as arguments to functions/methods.
- `RRs` "Robot Results objects" These are the MATLAB objects containing a collection of trials in one experimental session. This class contains methods and processing for across-trial analysis and modeling.

## Software Used
- Windows 11
- MATLAB 2024a

## Data Sharing Information

Repository: *put the name of the repository you intend to submit to here. If there isn't one, put N/A.
Data is accessible via the following link: *put your link to the repository here, if there isn't one, you can delete this line

