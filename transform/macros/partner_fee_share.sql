{% macro partner_fee_share(pbm_fee, fee_cents, fee_percentage) %}
{#-
  The partner's cut of the PBM fee. Exactly one of the two terms is populated.
  fee_cents is in CENTS and pbm_fee is in DOLLARS, so the flat term is divided
  by 100. Getting this wrong inflates flat partners 100x and is the single
  easiest error to make in this dataset.
  A flat cut is capped at the fee actually collected: we cannot pay out more
  than we took in.
  A claim with no converting lookup has no partner, and so no share.
-#}
case
    when {{ fee_cents }} is not null
        then least({{ fee_cents }} / 100.0, {{ pbm_fee }})
    when {{ fee_percentage }} is not null
        then {{ pbm_fee }} * ({{ fee_percentage }} / 100.0)
    else 0.0
end
{% endmacro %}
