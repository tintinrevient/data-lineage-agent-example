with source as (
  select * from {{ source('testuser', 'orders') }}
),

renamed as (
  select
    order_id,
    customer_id,
    order_date,
    status,
    total_amount,
    updated_at
  from source
)

select * from renamed
