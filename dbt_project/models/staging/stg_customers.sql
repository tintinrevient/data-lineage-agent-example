with source as (
  select * from {{ source('testuser', 'customers') }}
),

renamed as (
  select
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    created_at,
    updated_at
  from source
)

select * from renamed
