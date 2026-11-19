
SELECT
    review_id,
    order_id,
    review_score,
    case
        when trim(review_comment_title) = '' then null
        else review_comment_title
    end as review_comment_title,
    case
        when trim(review_comment_message) = '' then null
        else review_comment_message
    end as review_comment_message,
    review_creation_date::timestamp as review_created_at,
    review_answer_timestamp::timestamp as review_answered_at
FROM {{ source('olist', 'order_reviews') }}