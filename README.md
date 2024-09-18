# About this repository
📘 This project is building smart # Aptopus User Management Contract

This smart contract manages user accounts, chat requests, and credit systems on the Aptos blockchain.

## Table of Contents

1. [Overview](#overview)
2. [Structures](#structures)
3. [Events](#events)
4. [Key Functions](#key-functions)
5. [Usage](#usage)

## Overview

The Aptopus User Management Contract provides functionality for:

- Creating user accounts
- Submitting chat requests
- Purchasing credits (score)
- Managing user scores

## Structures

## Account contract for mamaging account for aptopus products: 

![User Account Move](https://github.com/user-attachments/assets/47c5ad8d-69bb-4793-8485-c7ff5ffe058b)

## Represents a user account with name, address, score (credits), and resolved chat requests.

![User Account Move (2)](https://github.com/user-attachments/assets/4362f796-a6ce-4e8a-bbd3-e2b906553d8c)

## Stores information about resolved chat requests.
![User Account Move (1)](https://github.com/user-attachments/assets/1ffbc002-d8c6-4486-96b2-2404b4824259)


## Manages all user accounts on the platform.
![User Account Move (3)](https://github.com/user-attachments/assets/96d5a33e-9812-4e34-9d40-02e137d866b9)



## Events 

![Events napkin selection](https://github.com/user-attachments/assets/b47f9d66-b1b5-4c5b-8aec-fbbf2b513617)



# 🚀 Objective

# Function

# Get Started
1. Clone this repo:
```bash
git clone https://github.com/Weminal-labs/Aptous-smart-contract.git
```
2. Init an aptos account (aptopus in example)
```bash
aptos init --profile profilename
```
3. Faucet (devnet or testnet)
```bash
aptos account fund-with-faucet --account profilename --faucet-url https://faucet.devnet.aptoslabs.com --url https://fullnode.devnet.aptoslabs.com
```
4. Compile smartcontract
```bash
aptos move compile --named-addresses aptopus=profilename
```
5. Publish the contract
```bash
aptos move publish --included-artifacts none --named-addresses aptopus=profilename --profile=profilename
```
# 📑 Lisence
This project is owned by Weminal lab
