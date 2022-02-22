*** Settings ***
Documentation  Set of Keywords for GPU support


*** Keywords ***
Verify Installed CUDA Version
    [Documentation]  Checks the installed CUDA version
    [Arguments]  ${expected_version}
    Run Cell And Check Output    !nvidia-smi | grep "CUDA Version:" | awk '{split($0,a); print a[9]}'
    ...    ${expected_version}

Verify CUDA Is Not Installed
    [Documentation]  Verifies that CUDA is not installed
    Run Cell And Check Output    !nvidia-smi    /usr/bin/sh: nvidia-smi: command not found

Verify Pytorch Can See GPU
    [Documentation]    Verifies that PyTorch can see a GPU
    [Arguments]    ${install}=False
    IF  ${install}==True
        # TODO: use Install And Import Package In JupyterLab after #202 is merged
        Run Cell And Check For Errors  !pip install torch==1.8 numpy==1.19
    END
    Run Cell And Check Output
    ...    import torch; device = "cuda" if torch.cuda.is_available() else "cpu"; print(f"Using {device} device")
    ...    Using cuda device

Verify Tensorflow Can See GPU
    [Documentation]    Verifies that Tensorflow can see a GPU
    [Arguments]    ${install}=False
    IF  ${install}==True
        # TODO: use Install And Import Package In JupyterLab after #202 is merged
        Run Cell And Check For Errors  !pip install tensorflow==2.7
    END
    # Need to wrap output in double quotes
    ${out} =  Run Cell And Get Output  import tensorflow as tf; import os; os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'; tf.config.list_physical_devices('GPU')  # robocop: disable
    Should Be Equal  "${out}"  "[PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]"
