# check_jenkins

Returns the status of a jenkins job

## Features

check_jenkins features the following:
 * Authentication with jenkins (optional)
 * Query the status of a job

## Simple Usage

With authentication:
```
$ ./check_jenkins -U http://your-jenkins-instance.com -j job_name -U USERNAME -P PASSWORD
```

Without authentication:
```
$ ./check_jenkins -U http://your-jenkins-instance.com -j job_name
```
