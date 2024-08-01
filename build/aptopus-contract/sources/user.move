module aptopus::user {
    use std::string::{String, Self};
    use std::vector::{Self};
    use aptos_framework::signer::{Self};
    use aptos_framework::timestamp::{CurrentTimeMicroseconds};
    use std::option::{Option, Self};


    const  ERROR_ACCOUNT_EXISTED: u64 = 1;

    struct Account has key, store, copy {
        name: String,
        user_address: address,
        score: u64,
    }

    struct Admin has key, store, copy {
        accounts: vector<Account>,
    }

    struct Request has key, store, copy {
        user_address: address,
        proof: u64
    }

    // event
    #[event]
    struct AccountCreatedEvent {
        user_address: address,
        init_time: CurrentTimeMicroseconds,
    }

    fun init_module(s: &signer) {
        let admin = Admin {
            accounts: vector::empty(),
        };
        let admin_addr = signer::address_of(s);
        move_to(s, admin);
    }

    public entry fun create_account(s: &signer, name: String) acquires Admin {
        assert!(!is_existed_account(signer::address_of(s)), ERROR_ACCOUNT_EXISTED);
        let admin = borrow_global_mut<Admin>(@aptopus);
        let account = Account {
            name: name,
            user_address: signer::address_of(s),
            score: 0,
        };
        vector::push_back(&mut admin.accounts, account);
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


    //view function 
    #[view]
    public fun get_account_info(s: address): Option<Account> acquires Admin {
        //check
        if(!is_existed_account(s)) {
            return option::none();
        };
        return option::some(find_account_by_address(s))
    }

    // inner function


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
        }
    }
}



