SELECT
  i.plant_id,
  i.product_id,
  i.quantity_on_hand
FROM manufacturing_simple.inventory AS i
ORDER BY
  i.plant_id,
  i.product_id;