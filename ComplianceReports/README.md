Symphony-Powershell
Notes on the Scripts

These are Windows PowerShell Scripts that were written and tested on Powershell 5.1 which can be found here: https://www.microsoft.com/en-us/download/details.aspx?id=54616

You may also enjoy the Windows Powershell Ingtegrated Script Environment (ISE) described here: https://msdn.microsoft.com/en-us/powershell/scripting/core-powershell/ise/introducing-the-windows-powershell-ise

You must run "Set-ExecutionPolicy RemoteSigned" as described here: http://windowsitpro.com/powershell/running-powershell-scripts-easy-1-2-3

Modify the "Fill in these Variables" section for your specific pod and environment as well as a client certificate that will allow you to access Symphony. The service account used should have the User Management role.

In most cases summary information is output to the screen and if appropriate a CSV file is written to disk at the output path you sepcify 

The CSV file was designed for Microsoft Excel. To format in Excel follow these instructions:
        1. Open the CSV File in Excel
        2. Select Column A and click Data > "Text To Columns"
        3. Select "Delimited" and click Next
        4. Select only "Comma" and a "Text qualifier" of a single quote (') and click Next
        5. In the Data format screen scroll through the columns:
                a. Any date columns (for example, the user created, last updated and last login dates) change the "Column data format" to Date/YMD for each and click Finish
                b. User IDs can be formatted as a number with zero decimal places
        
        
These scripts use the REST API so at least one client certificate will need to be supplied in the p12 format with password: 

         $certificateFileAndPath="C:\mycerts\mycert.p12" - Bot client cert in p12 format
         $certificateFilePassword="password"             - Bot client cert file password
    
 
You will also need to specify your pod URLs

        $sessionAuthUrl="https://mycompany-api.symphony.com:8444/sessionauth/v1/authenticate" - Pod endpoint to get a sessionauth token
        $podUrl="https://mycompany.symphony.com:443" - pod URL for all pod calls
        $agentUrl = "https://mycompany.symphony.com/agent" - Agent url for all agent calls

Many also request an output folder for the CSV file:

        $outpoutPath="c:\myreportoutput\" - Folder into which CSV file will be written

