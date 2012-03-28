SELECT
  DISTINCT ticket.tn AS chamado, 
    ticket.create_time AS abertura, 
    ticket.title AS descricao, 
    ticket.customer_user_id AS solicitante, 
    queue.name AS fila,
    ticket_type.name AS tipo, 
    --users.login AS solucionador, 
    ticket_state.name AS estado, 
    service.name AS atividade 
FROM ticket 
    LEFT JOIN otrs.queue ON ticket.queue_id = queue.id 
    LEFT JOIN otrs.ticket_type ON ticket.type_id = ticket_type.id 
    --LEFT JOIN otrs.users ON ticket.user_id = users.id 
    LEFT JOIN otrs.ticket_state ON ticket.ticket_state_id = ticket_state.id 
    LEFT JOIN otrs.service ON ticket.service_id = service.id 
    --LEFT JOIN otrs.time_accounting G ON ticket.id = G.ticket_id 
    --LEFT JOIN otrs.ticket_history h ON ticket.id = h.ticket_id 
WHERE
  ticket.ticket_state_id IN (1,4,12,13,14) AND
  queue.id IN(8,9,12) 
ORDER BY
  abertura LIMIT 0, 1000