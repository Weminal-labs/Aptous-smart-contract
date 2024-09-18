module aptopus::user {
    use std::string::{String, Self};
    use std::vector::{Self};
    use aptos_framework::signer::{Self};
    use aptos_framework::timestamp::{CurrentTimeMicroseconds, now_microseconds};
    use std::option::{Option, Self, is_none, extract};
    use aptos_framework::event;
    use aptos_framework::coin::{transfer, Self, Coin};
    use aptos_framework::aptos_coin::AptosCoin;

    const INITIAL_SCORE: u64 = 10_000;
    const ERROR_ACCOUNT_EXISTED: u64 = 1;
    const ERROR_ACCOUNT_NOT_FOUND: u64 = 2;
    const NOT_ENOUGH_SCORE: u64 = 3;

    // struct definition for account, requires: 
    // name: user name,
    // user_address: user address,
    // score: user score or creadits for using the chat service,
    // resolved_requests: store the chat requests which have been resolved 
    struct Account has key, store, copy, drop {
        name: String,
        user_address: address,
        score: u64,
        resolved_requests: vector<ResolvedRequest>,
    }

    //struct resolved request, it requires:
    //  user_address, 
    //  num_of_tokens that is user pay for chat, 
    //  timestamp: the time when the chat request is resolved
    struct ResolvedRequest has key, store, copy, drop {
        user_address: address,
        num_of_tokens: u64,
        timestamp: u64,
    }

    // Admin struct requires account list to store all the accounts on the platform
    struct Admin has key, store, copy {
        accounts: vector<Account>,
    }


    struct Request has key, store, copy {
        user_address: address,
        proof: u64,
        score: u64,
    }

    // event
    #[event]
    struct AccountCreatedEvent has drop, store {
        user_address: address,
        init_time: u64,
    }

    #[event]
    struct ChatRequestSubmittedEvent has drop, store {
        user_address: address,
        num_of_tokens: u64,
        init_time: u64,
    }

    #[event] //event struct for creadits purchase request successful
    struct ScoreRequestedEvent has drop, store {
        user_address: address,
        amount: u64, // amount of creadits purchased
        init_time: u64, // timestamp when the request is made
    }

    fun init_module(s: &signer) {
        // init admin and store it in the aptopus account
        let admin = Admin {
            accounts: vector::empty(), 
        };
        let admin_addr = signer::address_of(s);
        move_to(s, admin);
    }


    // function to check if the account is existed
    fun is_existed_account(user_address: address): bool acquires Admin {
        let admin = borrow_global<Admin>(@aptopus);
        let accounts = &admin.accounts;
        let account_index  = 0;
        // loop to check if the account is existed return true else return false
        while (account_index < vector::length(accounts)) {
            let account = vector::borrow(accounts, account_index);
            if(account.user_address == user_address) {
                return true;
            };
            account_index = account_index + 1;
        };
        return false
    }

    //entry functions
    // function to create account
    public entry fun create_account(s: &signer, name: String) acquires Admin {
        // check if the account is existed
        assert!(!is_existed_account(signer::address_of(s)), ERROR_ACCOUNT_EXISTED);
        let admin = borrow_global_mut<Admin>(@aptopus);
        // create new account
        let account = Account {
            name: name,
            user_address: signer::address_of(s),
            score: INITIAL_SCORE,
            resolved_requests: vector::empty(),
        };
        // push the account to the admin account list
        vector::push_back(&mut admin.accounts, account);
    }

    // function to submit chat request
    public entry fun submit_chat_request(s: &signer, num_of_tokens: u64) acquires Admin {
        //todo
        //check if account is existed
        assert!(is_existed_account(signer::address_of(s)), ERROR_ACCOUNT_NOT_FOUND);
        let admin = borrow_global_mut<Admin>(@aptopus);
        let account_index = 0;
        // loop to find account by address to handle chat request
        while (account_index < vector::length(&admin.accounts)) {
            let account = vector::borrow_mut<Account>(&mut admin.accounts, account_index);
            if(account.user_address == signer::address_of(s)) {
                //check if user has enough creadits
                assert!(check_score(account, num_of_tokens), NOT_ENOUGH_SCORE);
                let curr_score = account.score;
                account.score = curr_score - num_of_tokens;
                // store chat request
                store_chat_request(account, num_of_tokens);
                break;
            };
            account_index = account_index + 1;
        };

        //emit event to notify client that chat request has been submitted
        event::emit(ChatRequestSubmittedEvent {
            user_address: signer::address_of(s),
            num_of_tokens: num_of_tokens,
            init_time:now_microseconds() , //timestamp when the request is made
        });

        //frontend catch event and resolve chat request
    }

    // function to request for purchase creadits
    public entry fun request_for_score(s: &signer, amount: u64) acquires Admin {
        // check that the account is existed
        assert!(is_existed_account(signer::address_of(s)), ERROR_ACCOUNT_NOT_FOUND);
        // transfer aptos coin from user account to aptopus account
        coin::transfer<AptosCoin>(s, @aptopus, amount);
        let admin = borrow_global_mut<Admin>(@aptopus);
        let account_index = 0;
        // loop to find account by address and give creadits
        while (account_index < vector::length(&admin.accounts)) {
            let account = vector::borrow_mut<Account>(&mut admin.accounts, account_index);
            // check if address is matched with the current account
            if(account.user_address == signer::address_of(s)) {
                let curr_score = account.score;
                account.score = curr_score + amount;
                break;
            };
            account_index = account_index + 1;
        };
        
        // after purchase success, emit an event to notify lient that creadits have been added
        event::emit(ScoreRequestedEvent {
            user_address: signer::address_of(s),
            amount: amount,
            init_time: now_microseconds(),
        });
    }
    

    //view functions
    #[view]
    public fun get_account_info(s: address): Option<Account> acquires Admin {
        //check if account is existed
        if(!is_existed_account(s)) {
            return option::none();
        };
        // return option of account
        return option::some(find_account_by_address(s))
    }


    // inner function
 

    // return current score of an account
    fun get_score(account: &Account): u64 {
        account.score
    }

    // update score of an account
    fun update_score(account: &mut Account, score: u64) {
        account.score = score;
    }

    // check if account has enough creadits
    fun check_score(account: &Account, num_of_token: u64): bool {
        account.score >= num_of_token
    }

    // store chat request in resolved request list
    fun store_chat_request(account: &mut Account, num_of_tokens: u64) {
        //todo
        let vec = &mut account.resolved_requests;
        vector::push_back(vec, ResolvedRequest {
            user_address: account.user_address,
            num_of_tokens: num_of_tokens,
            timestamp: now_microseconds(),
        });
    }

    // find account by address
    fun find_account_by_address(user_address: address) : Account acquires Admin {
        let admin = borrow_global<Admin>(@aptopus);
        let account_index = 0;
        // loop to find account by address
        while (account_index < vector::length(&admin.accounts)) {
            let account = vector::borrow<Account>(&admin.accounts, account_index);
            if(account.user_address == user_address) {
                return *account;
            };
            account_index = account_index + 1;
        };
        // return empty account if not found
        return Account {
            name: string::utf8(b""),
            user_address: @0x0cf,
            score: 0,
            resolved_requests:vector::empty(),
        }
    }
}



