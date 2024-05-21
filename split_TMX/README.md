# Powershell script to split a TMX into a number of smaller parts.

## To use the script

1. **Save the Script**:

   - Select the `splitTMX.ps1` file and download from Github
   - Create a new folder and save the script into that folder. For example `c:\Scripts`

2. **Open PowerShell**:

   - Press `Win + X` and select `Windows PowerShell` or `Windows PowerShell (Admin)` if you need administrative privileges.

3. **Navigate to the Script Directory**:

   - Use the `cd` command to navigate to the directory where you saved the `SplitTMX.ps1` file. For example, if you saved it in `C:\Scripts`, you would type:
     cd C:\Scripts

4. **Run the Script**:

By default, the PowerShell execution policy might prevent scripts from running. You can bypass this restriction temporarily by using the `-ExecutionPolicy Bypass` parameter when running the script:

`powershell -ExecutionPolicy Bypass -File .\SplitTMX.ps1`

The script includes some detailed debugging output to track the progress and identify any issues with the extraction and splitting of the TMX file.  Please run the script and observe the output for any errors or unexpected behaviour. It should run as shown in the video to [this post in the RWS Community](https://community.rws.com/product-groups/trados-portfolio/trados-studio/f/studio/52741/how-to-split-tmx-translation-memory-by-size/168012).

