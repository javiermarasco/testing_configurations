# Let's test our configurations with Powershell and Pester

I tend to automate everything, it makes sense that if there is something you are requested to do more than once and the time you need to invest to automate it is not huge, you will spend some time automating it. But I often found myself having a configuration file to not need to deal with modifying my scripts, I simply create a script that does the job and provide the script with configuration files as input.
This is a very nice approach when you don't want to have parameters in your scripts as well.

But then, you communicate this in your company and more people start using your automation, you of course know how the config file should look like, but what if others are not aware? what if that automation ends up in a pipeline? you have the usage documented (of course you do!) but probably others are not aware of it.

So.... how do you ensure your script is used in a safe way and your configuration file is honored? well, keep reading and I will show you how I do it :)

## General idea

Let's think that we have a terraform file that will build some resources in the cloud, and you are providing this terraform plan a JSON file, inside the terraform plan you decode the JSON and use the contents to provide of values to you resources.

Since this JSON is something you create, the format is what ever it makes sense for your needs, it can have any format and any amount of fields, but you need to be aware that depending on the structure you give to it the tests might change a bit.


## Example configuration file

For this example I will go with a general JSON file that I made for this example, if contains arrays, nested objects, booleans and arrays inside nested objects.

```json
[
    {
        "vnet_name": "demo-vnet-name-1",
        "resource_group_name": "resource_groupname",
        "address_space": [
            "10.0.0.0/23"
        ],
        "dns_servers": [
            "10.0.1.0",
            "10.0.0.128"
        ],
        "vnet_location": "eastus2",
        "Subnets": {
            "name": "misubnet",
            "address_prefixes": [
                "10.0.0.0/24",
                "10.0.0.128/24"
            ]
        },
        "Enabled" : true
    },
    {
        "vnet_name": "demo-vneT-name",
        "resource_group_name": "resource_groupname",
        "address_space": [
            "10.0.2.0/24"
        ],
        "dns_servers": [
            "10.0.1.12"
        ],
        "vnet_location": "eastus3",
        "Subnets": {
            "name": "misubnet2",
            "address_prefixes": [
                "10.0.2.0/24",
                "10.0.2.128/24"
            ]
        },
        "Enabled" : false
    }
]

```

This configuration file is an array that contains 2 definitions to build two hypothetical network resources.

## Thinking process

The first thing we want to do is to sit, relax and watch our configuration file, think on what make sense to validate and what doesn't, we don't want to write kilometers of tests when we don't need to validate all, maybe there are fields that are ok to have any value on them (like tags, we probably don't care if the tag is correct), while others are very important to validate, like a naming convention.

Once we saw what we want to write a test for, our next step is to write down a list of test we want to address, let's do that.

I want to test:

1) My vnet_name is not empty
2) I want to check the vnet_name is following my naming convention (very simple needs to have 4 sections)
3) My vnet_name is composed of only lower case letters
4) The location for the resources needs to be one that I "approve" to build on

With this list, we are ready to start writing our tests.

## Pester

### What it is

Pester is a test framework for powershell, is very easy to use, contains a lot of methods/keywords to run our assertions and it's installation and configuration can't be simpler.
Using Pester we will be writing blocks called "Descriptions" defined by the word "Describe" which are logical ways to split our assertions, inside each "Describe" block we will be creating one or more "It" asserts, each one of those will run a validation and will be reported as a "Passed" or "Failed" assertion.

In the output, when you run the "Invoke-Pester" command with the "-Output Detailed" parameter, the "Describe" block will be grouping the "It" asserts, so it will be easier to read as an output.


### How to install (Windows)

To install Pester is as simple as install it from the PSGallery following [this](https://pester-docs.netlify.app/docs/introduction/installation) guide.

The key steps are:

1) Open a powershell terminal as administrator
2) Run `Install-Module -Name Pester -Force -SkipPublisherCheck`

No big mystery here, it will install pester as a module in your host and let it ready to use.

### How it works

As mentioned before, writing a test is simply create `Describe` blocks to group similar assertions and inside those blocks, write one `It` block for each assertion.

For the `Describe` blocks, there is not much to say, you place a name on them and nothing more.

For the `It` asserts is different, in them you can pass a `TestCase` which is an array of elements that the assert will evaluate one by one or you can simply skip that and inside the `It` block write the code to make the validation.

When you write an assertion you want to do an operation and then pipe it to the `should` operator (which is part of what you install with Pester). This `should` operator has some parameters that you can use to describe what are you expecting the evaluation will return.

Some parameters for `should` are:

- Be: Compares the evaluation result to a desired value
- Not: Inverts the boolean of the evaluation
- BeNullOrEmpty: Checks if the evaluation is an empty string or not defined at all
- BeGreaterThan: Checks if the evaluation is greater than a defined value
- BeLessThan: Checks if the evaluation is less than a defined value

[Here](https://pester-docs.netlify.app/docs/commands/Should) you can find the complete list

Once you have your test written, you can call it by running `Invoke-Pester -Path <file.ps1>` and if you like the verbose output (like me) add `-Output Detailed`

## Example Pester test

We are going to be using Pester 5.3.1 in this guide, next I will split my test in sections to explain them next:

### Pre tests data

We will need some elements before we can start testing stuff, this is to define certain values for the tests.

```powershell
# We retrieve the configuration to test
$configfile = Get-Content -path "./configuration.json" | ConvertFrom-Json -Depth 4

# Define the list of approved regions to deploy resources
$Regions = @('eastus2','eastus')

# We create an empty array to pass to our tests
$TestCases = @()

# We populate our test cases creating elements named "Instance" for each entry in our config file
foreach ($item in $configfile) {
    $TestCases += @{Instance = $item }
}
```

### "My vnet_name is not empty"

Let's define the test for this

```powershell
# Example to verify if the value was defined, this prevents missing important fields.
Describe "Check vnet_name is defined." -Verbose {
    It "Verify the name is set in <Instance.vnet_name>." -TestCases $TestCases -Verbose {
        Param($Instance)
        $Instance.vnet_name | should -not -Benullorempty
    }
}
```
In here we are using the "should", "not" and "benullorempty" to compare with the value we got from the configuration, Pester already have all this functions ready for use to use.

### Check naming convention

In this one we are going to assume our naming convention is something that needs to have 4 segments separated by a "-". This is a very simple check, think that you can even validate each of those sections and see if their values are correct.
Another useful check is to validate if there are no other resources already created with this name.
Keep in mind you can have multiple "It" commands inside a "Describe" section.

```powershell
# Example to verify namingconvention, this helps to enforce we don't create resources wrongly named.
Describe "Check naming convention for vnet_name." -Verbose {
    It "Verify the vnet_name for <Instance.vnet_name> matches naming convention length." -TestCases $TestCases -Verbose {
        Param($Instance)
        $Instance.vnet_name.split("-").count | should -be 4
    }
}    
```

### Only lower letters are allowed on the vnet_name

This one is very interesting, we are going to use regular expressions to check if the name we are providing is composed of lower case letters, regular expressions are very powerfull and we can write really good tests by using them to define what we are expecting.

In this example cmath is for case sensitive matches and imatch is used fo case insensitive matches.

```powershell
# Example to validate our names are all lowercase, useful for resources that doesn't support uppercase
# here the cmatch uses a regular expression, this can be adjusted to match any patter we need.
Describe "Check name for vnet_name should be all lowercase." -Verbose {
    It "Verify <Instance.vnet_name> is all lowercase." -TestCases $TestCases -Verbose {
        Param($Instance)
        $Instance.vnet_name -cmatch "^[^A-Z]*$" | should -be $true
    }
} 
```

### Validate we are only deploying to approved locations

At the beginning of this section we defined a list of approved locations, we will use that to validate the location in our configuration is in that list.

```powershell
# Example on how to validate a value in an array of values, like in this case where an 
# approved list of regions is given to the test to validate we build in the approved locations/regions.
Describe "Check location/region to deploy." -Verbose {
    It "Verify if region for <Instance.vnet_name> is approved." -TestCases $TestCases -Verbose {
        Param($Instance)
        $Regions -contains $Instance.vnet_location | should -be $true
    }
}
```

## Final notes

As usual, you can find my other networks in [here](https://linktr.ee/javi__codes)

If you find this useful or have any recommendation, please let me know in the comments, follow me for future posts so I know which content is more desired by the community and I can focus on produce more of it and I hope you enjoyed it.

Thanks for reading!!