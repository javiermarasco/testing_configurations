# We retrieve the configuration to test
$configfile = Get-Content -path "./configuration.json" | ConvertFrom-Json -Depth 4
$Regions = @('eastus2','eastus')

# We create an empty array to pass to our tests
$TestCases = @()

# We populate our test cases creating elements named "Instance" for each entry in our config file
foreach ($item in $configfile) {
    $TestCases += @{Instance = $item }
}

# Example to verify if the value was defined, this prevents missing important fields.
Describe "Check vnet_name is defined." -Verbose {
    It "Verify the name is set in <Instance.vnet_name>." -TestCases $TestCases -Verbose {
        Param($Instance)
        $Instance.vnet_name | should -not -Benullorempty
    }
}

# Example to verify namingconvention, this helps to enforce we don't create resources wrongly named.
Describe "Check naming convention for vnet_name." -Verbose {
    It "Verify the vnet_name for <Instance.vnet_name> matches naming convention length." -TestCases $TestCases -Verbose {
        Param($Instance)
        $Instance.vnet_name.split("-").count | should -be 4
    }
}    

# Example to validate our names are all lowercase, useful for resources that doesn't support uppercase
# here the cmatch uses a regular expression, this can be adjusted to match any patter we need.
Describe "Check name for vnet_name should be all lowercase." -Verbose {
    It "Verify <Instance.vnet_name> is all lowercase." -TestCases $TestCases -Verbose {
        Param($Instance)
        $Instance.vnet_name -cmatch "^[^A-Z]*$" | should -be $true
    }
} 
    
# Example on how to validate a value in an array of values, like in this case where an 
# approved list of regions is given to the test to validate we build in the approved locations/regions.
Describe "Check location/region to deploy." -Verbose {
    It "Verify if region for <Instance.vnet_name> is approved." -TestCases $TestCases -Verbose {
        Param($Instance)
        $Regions -contains $Instance.vnet_location | should -be $true
    }
}


