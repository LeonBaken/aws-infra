# How to use this
1. Clone this repo to your computer
2. use "terraform apply" to start the program
3. the program will ask you about parameters to put in, just follow the request


aws --profile demo acm import-certificate --certificate fileb://demo_junliang_me.crt --certificate-chain fileb://demo_junliang_me.ca-bundle --private-key fileb://server.key