*** Settings ***
Resource   ODHDashboard.robot
Library    RequestsLibrary
Library    SeleniumLibrary

*** Variables ***
${PARTNER_BADGE_TITLE}=  Partner managed
${SELF_BADGE_TITLE}=  Self-managed
${RH_BADGE_TITLE}=  Red Hat managed
${CMS_BADGE_TITLE}=  Coming soon
${BETA_BADGE_TITLE}=  Beta
