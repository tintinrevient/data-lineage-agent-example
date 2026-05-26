{{
    config(
        materialized='view',
        tags=['orders', 'mart']
    )
}}

with orders as (

    select * from {{ ref('stg_orders') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

order_items as (

    select * from {{ ref('stg_order_items') }}

),

order_item_agg as (

    select
        order_id,
        count(order_item_id)        as item_count,
        sum(quantity)               as total_quantity,
        sum(line_total)             as items_total_amount

    from order_items
    group by order_id

),

joined as (

    select
        o.order_id,
        o.order_date,
        o.status,
        o.total_amount,
        c.customer_id,
        c.email                         as customer_email,
        oi.item_count,
        oi.total_quantity,
        oi.items_total_amount,
        o.updated_at

    from orders o
    inner join customers c
        on o.customer_id = c.customer_id
    left join order_item_agg oi
        on o.order_id = oi.order_id

)

select * from joined