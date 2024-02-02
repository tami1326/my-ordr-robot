*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML recipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the image. 
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.Tables
Library    RPA.HTTP
Library    RPA.Excel.Files
Library    RPA.Desktop
Library    RPA.PDF
Library    RPA.Archive
Library    OperatingSystem

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download CSV file
    Get orders from CSV file and fill in the forms
    Create ZIP file 
    Clean up

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order 

Accept cookies
    Wait Until Element Is Visible    xpath://div[@class="alert-buttons"]
    Click Button    xpath://button[@class="btn btn-warning"]
    
Download CSV file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Get orders from CSV file and fill in the forms
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Log    ${order}[Order number]
        Fill and submit the form    ${order}
    END
    

Fill and submit the form
    [Arguments]    ${order}
    Accept cookies
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://input[@class="form-control"][1]    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    id:order
    Search for error    ${order}

Search for error 
    [Arguments]    ${order}
    ${error}=    Set Variable    ${TRUE}
    WHILE    $error==$True
        Wait Until Element Is Visible    id:robot-preview-image
        ${error}=    Run Keyword And Return Status    Page Should Not Contain Element    xpath://div[@class="alert alert-danger"]
        IF   $error==$True
            Save file as PDF
            Take screenshot of robot
            Embed image in PDF    ${order} 
            Click Button    id:order-another
            BREAK
        ELSE
            Run Keyword And Ignore Error    Scroll Element Into View    id:order
            Click Button    id:order
            ${error}=    Set Variable    ${TRUE}
        END
    END

Save file as PDF
    Wait Until Element Is Visible    id:receipt
    ${current_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${current_receipt_html}    ${OUTPUT_DIR}${/}current_receipt.pdf

Take screenshot of robot
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot_picture.png
    
Embed image in PDF
    [Arguments]    ${order}
    Open Pdf    ${OUTPUT_DIR}${/}current_receipt.pdf
    Add Watermark Image To Pdf    ${OUTPUT_DIR}${/}robot_picture.png    ${OUTPUT_DIR}${/}${order}[Order number].pdf
    Close Pdf

Create ZIP file
    Archive Folder With Zip    ${OUTPUT_DIR}    all_orders.zip    include=*.pdf 
    
Clean up
    Remove Files    ${OUTPUT_DIR}${/}*.pdf
    Close Browser