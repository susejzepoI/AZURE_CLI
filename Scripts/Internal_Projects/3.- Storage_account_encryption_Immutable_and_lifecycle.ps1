#Author         :   Jesus Lopez Mesia
#Linkedin       :   https://www.linkedin.com/in/susejzepol/
#Created date   :   November-20-2024
#Modified date  :   November-20-2024
#script Purpose :   Manage storage account lifecycle rules, Encryption and immutable storage polices.

#JLopez: Import the module "print-message-custom-v1.psm1".
if($pwd.path -like "*Scripts"){
    $root = "."
}elseif ($pwd.path -like "*Internal_projects") {
    $root = ".."
}else {
    $root = ".\Scripts"
}
Import-Module  "$root\utilities\print-message-custom-v1.psm1"