1. Clone the repository
2. Export the username and password vars and create an alias using the profile file
```
export CM_PASSWORD=$YOUR_CM_ACCOUNT_PASSWORD
export CM_USERNAME=$YOUR_CM_ACCOUNT_USERNAME
alias cm="oldPWD=${PWD}; cd ~/git/cyberianmine; clear; ./miners_new/run.sh; ./miners_used/run.sh; ./miners_sell/run.sh; cd ${oldPWD}"
```

3. Import the updated profile file
```
. ~/.profile
```
4. Run the `cm` alias and wait for the results
