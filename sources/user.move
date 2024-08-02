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


    struct Account has key, store, copy, drop {
        name: String,
        user_address: address,
        score: u64,
        resolved_requests: vector<ResolvedRequest>,
    }

    struct ResolvedRequest has key, store, copy, drop {
        user_address: address,
        num_of_tokens: u64,
        timestamp: u64,
    }

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

    #[event]
    struct ScoreRequestedEvent has drop, store {
        user_address: address,
        amount: u64,
        init_time: u64,
    }

    fun init_module(s: &signer) {
        let admin = Admin {
            accounts: vector::empty(),
        };
        let admin_addr = signer::address_of(s);
        move_to(s, admin);
    }


    fun is_existed_account(user_address: address): bool acquires Admin {
        let admin = borrow_global<Admin>(@aptopus);
        let accounts = &admin.accounts;
        let account_index  = 0;
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
    public entry fun create_account(s: &signer, name: String) acquires Admin {
        assert!(!is_existed_account(signer::address_of(s)), ERROR_ACCOUNT_EXISTED);
        let admin = borrow_global_mut<Admin>(@aptopus);
        let account = Account {
            name: name,
            user_address: signer::address_of(s),
            score: INITIAL_SCORE,
            resolved_requests: vector::empty(),
        };
        vector::push_back(&mut admin.accounts, account);
    }

    public entry fun submit_chat_request(s: &signer, num_of_tokens: u64, score: u64) acquires Admin {
        //todo
        assert!(is_existed_account(signer::address_of(s)), ERROR_ACCOUNT_NOT_FOUND);
        let admin = borrow_global_mut<Admin>(@aptopus);
        let account_index = 0;
        while (account_index < vector::length(&admin.accounts)) {
            let account = vector::borrow_mut<Account>(&mut admin.accounts, account_index);
            if(account.user_address == signer::address_of(s)) {
            assert!(check_score(account, num_of_tokens), NOT_ENOUGH_SCORE);
                let curr_score = account.score;
                account.score = curr_score - num_of_tokens;
                store_chat_request(account, num_of_tokens);
                break;
            };
            account_index = account_index + 1;
        };
        event::emit(ChatRequestSubmittedEvent {
            user_address: signer::address_of(s),
            num_of_tokens: num_of_tokens,
            init_time:now_microseconds() ,
        });

        //frontend catch event and resolve chat request
    }

    public entry fun request_for_score(s: &signer, amount: u64) acquires Admin {
        assert!(is_existed_account(signer::address_of(s)), ERROR_ACCOUNT_NOT_FOUND);
        // let account = &mut find_account_by_address(signer::address_of(s));
        coin::transfer<AptosCoin>(s, @aptopus, amount);
        let admin = borrow_global_mut<Admin>(@aptopus);
        let account_index = 0;
        while (account_index < vector::length(&admin.accounts)) {
            let account = vector::borrow_mut<Account>(&mut admin.accounts, account_index);
            if(account.user_address == signer::address_of(s)) {
                let curr_score = account.score;
                account.score = curr_score + amount;
                break;
            };
            account_index = account_index + 1;
        };
        // update_score(account, curr_score + amount);
        event::emit(ScoreRequestedEvent {
            user_address: signer::address_of(s),
            amount: amount,
            init_time: now_microseconds(),
        });
    }
    

    //view functions
    #[view]
    public fun get_account_info(s: address): Option<Account> acquires Admin {
        //check
        if(!is_existed_account(s)) {
            return option::none();
        };
        return option::some(find_account_by_address(s))
    }


    // inner function
 

    fun get_score(account: &Account): u64 {
        account.score
    }

    fun update_score(account: &mut Account, score: u64) {
        account.score = score;
    }

    fun check_score(account: &Account, num_of_token: u64): bool {
        account.score >= num_of_token
    }

    fun store_chat_request(account: &mut Account, num_of_tokens: u64) {
        //todo
        let vec = &mut account.resolved_requests;
        vector::push_back(vec, ResolvedRequest {
            user_address: account.user_address,
            num_of_tokens: num_of_tokens,
            timestamp: now_microseconds(),
        });
    }


    fun find_account_by_address(user_address: address) : Account acquires Admin {
        let admin = borrow_global<Admin>(@aptopus);
        let account_index = 0;
        while (account_index < vector::length(&admin.accounts)) {
            let account = vector::borrow<Account>(&admin.accounts, account_index);
            if(account.user_address == user_address) {
                return *account;
            };
            account_index = account_index + 1;
        };
        return Account {
            name: string::utf8(b""),
            user_address: @0x0cf,
            score: 0,
            resolved_requests:vector::empty(),
        }
    }
}



