insert into tinder_swipes
    (tinder_account_id, right_swipe, created_at, updated_at)
select
    (
        select id
        from gologin_profiles
        where profile_id = '626e277d80fc497b0de09c80'
    ),
    true,
    NOW(),
    NOW();

