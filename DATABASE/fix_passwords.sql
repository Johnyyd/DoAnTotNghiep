USE [PharmaceuticalProcessingManagementSystem];
GO
UPDATE AppUsers SET PasswordHash = '$2a$11$wgjkyWOSyZDzeLRkuBeR4ubdBO6VLr67PIV/0xpSSMO07bF9iVnPG' WHERE Username IN ('qc01', 'qc02');
UPDATE AppUsers SET PasswordHash = '$2a$11$aSZ9sR9IaSoKSLBtsvIU5e2D5l4nOse8xk71l6pTYK2LXctQWS7E.' WHERE Username IN ('op01', 'op02', 'mgr01');
UPDATE AppUsers SET PasswordHash = '$2a$11$h8Y1M8sLpi1QDlBDzP1dYeMvp2RiYVXU/J6zYncuO9QHNjnhjT1gO' WHERE Username = 'admin';
GO
