# testing_configurations

In this repository you can find a framework to manage your configuration files for custom implementations:

## Motivation

Some times you need to make configuration files for your deployments, like while using terraform, and you also need to ensure
the configuration file is correct on aspects you can't test with terraform (think of naming conventions, features you are not allowing to be created, etc.).
In these cases you can't rely on terraform to test if they are correct so you need another way to make it

## Solution

This repository presents a way to accomplish this by defining the configuration in a json file and then run a pester test to validate 
if the configuration files is correct according to our desires.

