alter session set current_schema = parranderos;

-- Clasifique las bebidas en Suave (menos de 5 grados), Moderada (5 a 20) y Fuerte
-- (más de 20). Cuente cuántas bebidas hay en cada categoría.

select nombre,
       clasificacion,
       count(*)
       over(partition by clasificacion) as numero_bebidas_clasificacion
  from (
   select nombre,
          (
             case
                when grado_alcohol < 5 then
                   'Suave'
                when grado_alcohol >= 5
                   and grado_alcohol <= 20 then
                   'Moderada'
                else
                   'Fuerte'
             end
          ) as clasificacion
     from bebidas
);

-- Para cada bebedor, muestre cuántas bebidas le gustan y qué porcentaje
-- representa del total de registros de Gustan.

select distinct id_bebedor,
                round(
                   count(*)
                   over(partition by id_bebedor) / count(*)
                                                   over(),
                   4
                ) as pct_gustan
  from gustan;

-- Para cada bar, liste las dos bebidas más costosas que sirve, incluidas las que
-- empatan.

select nombre_bar,
       nombre_bebida,
       precio
  from (
   select id_bar,
          bares.nombre as nombre_bar,
          id_bebida,
          bebidas.nombre as nombre_bebida,
          rank()
          over(partition by id_bar
               order by precio desc
          ) as rank_costo_bebida_en_bar,
          precio
     from sirven
    inner join bares
   on sirven.id_bar = bares.id
    inner join bebidas
   on sirven.id_bebida = bebidas.id
)
 where rank_costo_bebida_en_bar <= 2;


-- Para cada día con visitas, calcule el consumo acumulado del mes. El acumulado se
-- reinicia al cambiar de mes.

select fecha_de_visita,
       sum(total_consumos_dia)
       over(partition by fecha_mes
            order by fecha_de_visita
       ) as consumo_acumulado_mes,
       fecha_mes
  from (
   select distinct trunc(fecha_visita) as fecha_de_visita,
                   sum(total_consumos)
                   over(partition by trunc(fecha_visita)) as total_consumos_dia,
                   substr(
                      trunc(fecha_visita),
                      4
                   ) as fecha_mes
     from visitas
)
 order by fecha_de_visita;

-- Calcule el promedio de consumos de los últimos 7 días y compárelo con el
-- promedio de las últimas 7 filas.

select fecha_visita,
       round(
          avg(total_consumos)
          over(
              order by fecha_de_visita
             range between interval '7' day preceding and current row
          ),
          4
       ) as avg_consumos_7_dias,
       round(
          avg(total_consumos)
          over(
              order by fecha_de_visita
             rows between 7 preceding and current row
          ),
          4
       ) as avg_consumos_7_filas
  from (
   select fecha_visita,
          trunc(fecha_visita) as fecha_de_visita,
          total_consumos
     from visitas
    order by fecha_visita
);
