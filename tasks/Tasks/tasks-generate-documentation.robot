*** Settings ***
Documentation    Tasks Generate Documentation

Resource  ../Resources/Tasks.resource

*** Tasks ***
Generate Resources Documentation
    Generate Documentation     tests/Resources/Page     docs/keywords
  