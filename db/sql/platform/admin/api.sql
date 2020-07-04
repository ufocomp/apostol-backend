--------------------------------------------------------------------------------
-- ADMIN API -------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.su ----------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Substitute user.
 * Меняет текущего пользователя в активном сеансе на указанного пользователя
 * @param {text} pUserName - Имя пользователь для подстановки
 * @param {text} pPassword - Пароль текущего пользователя
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.su (
  pUserName   text,
  pPassword   text
) RETURNS     void
AS $$
BEGIN
  PERFORM SubstituteUser(pUserName, pPassword);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- USER ------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.add_user ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт учётную запись пользователя.
 * @param {varchar} pUserName - Пользователь
 * @param {text} pPassword - Пароль
 * @param {text} name - Полное имя
 * @param {text} pPhone - Телефон
 * @param {text} pEmail - Электронный адрес
 * @param {text} pDescription - Описание
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION api.add_user (
  pUserName     varchar,
  pPassword     text,
  name          text,
  pPhone        text DEFAULT null,
  pEmail        text DEFAULT null,
  pDescription  text DEFAULT null
) RETURNS       numeric
AS $$
BEGIN
  RETURN CreateUser(pUserName, pPassword, name, pPhone, pEmail, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_user -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет учётную запись пользователя.
 * @param {numeric} pId - Идентификатор учетной записи
 * @param {varchar} pUserName - Пользователь
 * @param {text} pPassword - Пароль
 * @param {text} name - Полное имя
 * @param {text} pPhone - Телефон
 * @param {text} pEmail - Электронный адрес
 * @param {text} pDescription - Описание
 * @param {boolean} pPasswordChange - Сменить пароль при следующем входе в систему
 * @param {boolean} pPasswordNotChange - Установить запрет на смену пароля самим пользователем
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_user (
  pId                 numeric,
  pUserName           varchar,
  pPassword           text,
  name                text,
  pPhone              text,
  pEmail              text,
  pDescription        text,
  pPasswordChange     boolean,
  pPasswordNotChange  boolean
) RETURNS             void
AS $$
BEGIN
  PERFORM UpdateUser(pId, pUserName, pPassword, name, pPhone, pEmail, pDescription, pPasswordChange, pPasswordNotChange);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.delete_user -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Удаляет учётную запись пользователя.
 * @param {numeric} pId - Идентификатор учётной записи пользователя
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.delete_user (
  pId         numeric
) RETURNS     void
AS $$
BEGIN
  PERFORM DeleteUser(pId);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_user ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает учётную запись пользователя.
 * @return {SETOF users} - Учётная запись пользователя
 */
CREATE OR REPLACE FUNCTION api.get_user (
  pId		numeric DEFAULT current_userid()
) RETURNS	SETOF users
AS $$
DECLARE
  r         users%rowtype;
BEGIN
  FOR r IN SELECT * FROM users WHERE id = pId
  LOOP
    RETURN NEXT r;
  END LOOP;

  RETURN;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_user ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает учётные записи пользователей.
 * @return {SETOF users} - Учётные записи пользователей
 */
CREATE OR REPLACE FUNCTION api.list_user (
  pId		numeric DEFAULT null
) RETURNS	SETOF users
AS $$
DECLARE
  r         users%rowtype;
BEGIN
  FOR r IN SELECT * FROM users WHERE id = coalesce(pId, id)
  LOOP
    RETURN NEXT r;
  END LOOP;

  RETURN;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.change_password ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Устанавливает пароль пользователя.
 * @param {numeric} pId - Идентификатор учетной записи
 * @param {text} pOldPass - Старый пароль
 * @param {text} pNewPass - Новый пароль
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.change_password (
  pId           numeric,
  pOldPass      text,
  pNewPass      text
) RETURNS       void
AS $$
BEGIN
  IF NOT CheckPassword(GetUserName(pId), pOldPass) THEN
    RAISE EXCEPTION '%', GetErrorMessage();
  END IF;

  PERFORM SetPassword(pId, pNewPass);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.user_member -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список групп пользователя.
 * @return {record} - Группы
 */
CREATE OR REPLACE FUNCTION api.user_member (
  pUserId numeric DEFAULT current_userid()
) RETURNS TABLE (id numeric, username varchar, name text, description text)
AS $$
  SELECT g.id, g.username, g.name, g.description
    FROM db.member_group m INNER JOIN groups g ON g.id = m.userid
   WHERE member = pUserId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.member_user -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список групп пользователя.
 * @return {record} - Группы
 */
CREATE OR REPLACE FUNCTION api.member_user (
  pUserId numeric DEFAULT current_userid()
) RETURNS TABLE (id numeric, username varchar, name text, description text)
AS $$
  SELECT * FROM api.user_member(pUserId);
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.user_lock ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Блокирует учётную запись пользователя.
 * @param {numeric} pId - Идентификатор учётной записи пользователя
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.user_lock (
  pId           numeric
) RETURNS       void
AS $$
BEGIN
  PERFORM UserLock(pId);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.user_unlock -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Снимает блокировку с учётной записи пользователя.
 * @param {numeric} pId - Идентификатор учётной записи пользователя
 * @out param {numeric} result - Результат
 * @out param {text} message - Текст ошибки/результата
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.user_unlock (
  pId       numeric
) RETURNS   void
AS $$
BEGIN
  PERFORM UserUnlock(pId);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_user_iptable --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает таблицу IP-адресов в виде одной строки.
 * @param {numeric} pId - Идентификатор учётной записи пользователя
 * @param {char} pType - Тип: A - allow; D - denied'
 * @out param {numeric} id - Идентификатор учётной записи пользователя
 * @out param {char} type - Тип: A - allow; D - denied'
 * @out param {text} iptable - IP-адреса в виде одной строки
 * @return {text}
 */
CREATE OR REPLACE FUNCTION api.get_user_iptable (
  pId		numeric,
  pType		char
) RETURNS TABLE (id numeric, type char, iptable text)
AS $$
  SELECT pId, pType, GetIPTableStr(pId, pType);
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_user_iptable --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Устанавливает таблицу IP-адресов из строки.
 * @param {numeric} pId - Идентификатор учётной записи пользователя
 * @param {char} pType - Тип: A - allow; D - denied'
 * @param {text} pIpTable - IP-адреса в виде одной строки
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.set_user_iptable (
  pId       	numeric,
  pType     	char,
  pIpTable  	text
) RETURNS   	void
AS $$
BEGIN
  PERFORM SetIPTableStr(pId, pType, pIpTable);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GROUP -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.add_group ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт группу учётных записей пользователя.
 * @param {varchar} pGroupName - Группа
 * @param {text} name - Полное имя
 * @param {text} pDescription - Описание
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION api.add_group (
  pGroupName	varchar,
  name          text,
  pDescription  text DEFAULT null
) RETURNS       numeric
AS $$
BEGIN
  RETURN CreateGroup(pGroupName, name, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_group ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет учётные данные группы.
 * @param {numeric} pId - Идентификатор группы
 * @param {varchar} pGroupName - Группа
 * @param {text} name - Полное имя
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_group (
  pId           numeric,
  pGroupName    varchar,
  name          text,
  pDescription  text
) RETURNS       void
AS $$
BEGIN
  PERFORM UpdateGroup(pId, pGroupName, name, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.delete_group ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Удаляет группу.
 * @param {numeric} pId - Идентификатор группы
 * @out {numeric} id - Идентификатор группы
 * @out param {numeric} result - Результат
 * @out param {text} message - Текст ошибки
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.delete_group (
  pId           numeric
) RETURNS       void
AS $$
BEGIN
  PERFORM DeleteGroup(pId);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_group ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает группу.
 * @return {record} - Группа
 */
CREATE OR REPLACE FUNCTION api.get_group (
  pId         numeric
) RETURNS     SETOF groups
AS $$
  SELECT * FROM groups WHERE id = pId;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_group --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список групп.
 * @return {record} - Группы
 */
CREATE OR REPLACE FUNCTION api.list_group (
) RETURNS     SETOF groups
AS $$
  SELECT * FROM groups;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.member_group_add --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет пользователя в группу.
 * @param {numeric} pMember - Идентификатор пользователя
 * @param {numeric} pGroup - Идентификатор группы
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.member_group_add (
  pMember       numeric,
  pGroup        numeric
) RETURNS       void
AS $$
BEGIN
  PERFORM AddMemberToGroup(pMember, pGroup);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.member_group_delete -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Удаляет группу для пользователя.
 * @param {numeric} pMember - Идентификатор пользователя
 * @param {numeric} pGroup - Идентификатор группы, при null удаляет все группы для указанного пользователя
 * @out param {numeric} result - Результат
 * @out param {text} message - Текст ошибки
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.member_group_delete (
  pMember       numeric,
  pGroup        numeric
) RETURNS       void
AS $$
BEGIN
  PERFORM DeleteGroupForMember(pMember, pGroup);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.group_member_delete -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Удаляет пользователя из группу.
 * @param {numeric} pGroup - Идентификатор группы
 * @param {numeric} pMember - Идентификатор пользователя, при null удаляет всех пользователей из указанной группы
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.group_member_delete (
  pGroup        numeric,
  pMember       numeric DEFAULT null
) RETURNS       void
AS $$
BEGIN
  PERFORM DeleteMemberFromGroup(pGroup, pMember);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.member_group ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.member_group
AS
  SELECT * FROM MemberGroup;

GRANT SELECT ON api.member_group TO daemon;

--------------------------------------------------------------------------------
-- api.group_member ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список пользователей группы.
 * @return {TABLE} - Группы
 */
CREATE OR REPLACE FUNCTION api.group_member (
  pGroupId    numeric
) RETURNS TABLE (
  id          numeric,
  username    varchar,
  name        text,
  email       text,
  phone       text,
  status      text,
  description text
)
AS $$
  SELECT u.id, u.username, u.name, u.email, u.phone, u.status, u.description
    FROM db.member_group m INNER JOIN users u ON u.id = m.member
   WHERE m.userid = pGroupId;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.member_group ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список групп пользователя.
 * @return {TABLE} - Группы
 */
CREATE OR REPLACE FUNCTION api.member_group (
  pUserId     numeric DEFAULT current_userid()
) RETURNS TABLE (
  id          numeric,
  username    varchar,
  name        text,
  description text
)
AS $$
  SELECT id, username, name, description FROM api.member_user(pUserId)
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_groups_json ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.get_groups_json (
  pMember       numeric
) RETURNS       json
AS $$
DECLARE
  arResult      json[];
  r             record;
BEGIN
  FOR r IN SELECT * FROM api.member_user(pMember)
  LOOP
    arResult := array_append(arResult, row_to_json(r));
  END LOOP;

  RETURN array_to_json(arResult);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.is_user_role ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.is_user_role (
  pRole         numeric,
  pUser         numeric DEFAULT current_userid()
) RETURNS       boolean
AS $$
BEGIN
  RETURN IsUserRole(pRole, pUser);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.is_user_role ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.is_user_role (
  pRole         text,
  pUser         text DEFAULT session_username()
) RETURNS       boolean
AS $$
BEGIN
  RETURN IsUserRole(pRole, pUser);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- AREA ------------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.area_type
AS
  SELECT * FROM AreaType;

GRANT SELECT ON api.area_type TO daemon;

--------------------------------------------------------------------------------
-- api.get_area_type -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Позвращает тип зоны.
 * @param {numeric} pId - Идентификатор типа зоны
 * @return {record} - Запись
 */
CREATE OR REPLACE FUNCTION api.get_area_type (
  pId		numeric
) RETURNS	SETOF api.area_type
AS $$
  SELECT * FROM api.area_type WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.area
AS
  SELECT * FROM Area;

GRANT SELECT ON api.area TO daemon;

--------------------------------------------------------------------------------
-- api.add_area ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт зону.
 * @param {numeric} pParent - Идентификатор "родителя"
 * @param {numeric} pType - Идентификатор типа
 * @param {varchar} pCode - Код
 * @param {varchar} pName - Наименование
 * @param {text} pDescription - Описание
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION api.add_area (
  pParent       numeric,
  pType         numeric,
  pCode         varchar,
  pName         varchar,
  pDescription  text DEFAULT null
) RETURNS       numeric
AS $$
BEGIN
  RETURN CreateArea(pParent, pType, pCode, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_area -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет зону.
 * @param {numeric} pId - Идентификатор зоны
 * @param {numeric} pParent - Идентификатор "родителя"
 * @param {numeric} pType - Идентификатор типа
 * @param {varchar} pCode - Код
 * @param {varchar} pName - Наименование
 * @param {text} pDescription - Описание
 * @param {timestamp} pValidFromDate - Дата открытия
 * @param {timestamp} pValidToDate - Дата закрытия
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_area (
  pId               numeric,
  pParent           numeric DEFAULT null,
  pType             numeric DEFAULT null,
  pCode             varchar DEFAULT null,
  pName             varchar DEFAULT null,
  pDescription      text DEFAULT null,
  pValidFromDate    timestamp DEFAULT null,
  pValidToDate      timestamp DEFAULT null
) RETURNS           void
AS $$
BEGIN
  PERFORM EditArea(pId, pParent, pType, pCode, pName, pDescription, pValidFromDate, pValidToDate);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.delete_area -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Удаляет зону.
 * @param {numeric} pId - Идентификатор зоны
 * @out {numeric} id - Идентификатор зоны
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.delete_area (
  pId         numeric
) RETURNS     void
AS $$
BEGIN
  PERFORM DeleteArea(pId);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_area ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список подразделений.
 * @return {record} - Группы
 */
CREATE OR REPLACE FUNCTION api.list_area (
) RETURNS     SETOF api.area
AS $$
  SELECT * FROM api.area;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_area ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает данные зоны.
 * @return {record} - Данные зоны
 */
CREATE OR REPLACE FUNCTION api.get_area (
  pId         numeric
) RETURNS     SETOF api.area
AS $$
  SELECT * FROM api.area WHERE id = pId;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.member_area_add ---------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет пользователя или группу в зону.
 * @param {numeric} pMember - Идентификатор пользователя/группы
 * @param {numeric} pArea - Идентификатор зоны
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.member_area_add (
  pMember     numeric,
  pArea       numeric
) RETURNS     void
AS $$
BEGIN
  PERFORM AddMemberToArea(pMember, pArea);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.member_area_delete ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Удаляет зону для пользователя.
 * @param {numeric} pMember - Идентификатор пользователя
 * @param {numeric} pArea - Идентификатор зоны, при null удаляет все зоны для указанного пользователя
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.member_area_delete (
  pMember     numeric,
  pArea       numeric
) RETURNS     void
AS $$
BEGIN
  PERFORM DeleteAreaForMember(pMember, pArea);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.area_member_delete ------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Удаляет пользователя из зоны.
 * @param {numeric} pArea - Идентификатор зоны
 * @param {numeric} pMember - Идентификатор пользователя, при null удаляет всех пользователей из указанного зоны
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.area_member_delete (
  pArea       numeric,
  pMember     numeric DEFAULT null
) RETURNS     void
AS $$
BEGIN
  PERFORM DeleteMemberFromArea(pArea, pMember);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- VIEW api.member_area --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.member_area
AS
  SELECT * FROM MemberArea;

GRANT SELECT ON api.member_area TO daemon;

--------------------------------------------------------------------------------
-- api.area_member -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список участников зоны.
 * @return {SETOF record} - Запись
 */
CREATE OR REPLACE FUNCTION api.area_member (
  pAreaId     numeric
) RETURNS TABLE (
  id          numeric,
  type        char,
  username    varchar,
  name        text,
  email       text,
  description text,
  status      text,
  system      text
)
AS $$
  SELECT g.id, 'G' AS type, g.username, g.name, null AS email, g.description, null AS status, g.system
    FROM api.member_area m INNER JOIN groups g ON g.id = m.memberid
   WHERE m.area = pAreaId
  UNION ALL
  SELECT u.id, 'U' AS type, u.username, u.name, u.email, u.description, u.status, u.system
    FROM api.member_area m INNER JOIN users u ON u.id = m.memberid
   WHERE m.area = pAreaId;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.member_area -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает зоны доступные участнику.
 * @return {record} - Данные зоны
 */
CREATE OR REPLACE FUNCTION api.member_area (
  pUserId   numeric DEFAULT current_userid()
) RETURNS   SETOF api.area
AS $$
  SELECT *
    FROM api.area
   WHERE id in (
     SELECT area FROM db.member_area WHERE member = (
       SELECT id FROM db.user WHERE id = pUserId
     )
   )
   UNION ALL
  SELECT *
    FROM api.area
   WHERE id in (
     SELECT area FROM db.member_area WHERE member IN (
       SELECT userid FROM db.member_group WHERE member = (
         SELECT id FROM db.user WHERE id = pUserId
       )
     )
   )
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- INTERFACE -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.interface
AS
  SELECT * FROM Interface;

GRANT SELECT ON api.interface TO daemon;

--------------------------------------------------------------------------------
-- api.add_interface -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт интерфейс.
 * @param {varchar} pName - Наименование
 * @param {text} pDescription - Описание
 * @out param {numeric} id - Идентификатор интерфейса
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION api.add_interface (
  pName         varchar,
  pDescription  text DEFAULT null
) RETURNS       numeric
AS $$
BEGIN
  RETURN CreateInterface(pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_interface --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет интерфейс.
 * @param {numeric} pId - Идентификатор интерфейса
 * @param {varchar} pName - Наименование
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_interface (
  pId           numeric,
  pName         varchar,
  pDescription  text DEFAULT null
) RETURNS       void
AS $$
BEGIN
  PERFORM UpdateInterface(pId, pName, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.delete_interface --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Удаляет интерфейс.
 * @param {numeric} pId - Идентификатор интерфейса
 * @out {numeric} id - Идентификатор интерфейса
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.delete_interface (
  pId         numeric
) RETURNS     void
AS $$
BEGIN
  PERFORM DeleteInterface(pId);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_interface -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает данные интерфейса.
 * @return {record} - Данные интерфейса
 */
CREATE OR REPLACE FUNCTION api.get_interface (
  pId		numeric
) RETURNS	SETOF api.interface
AS $$
  SELECT * FROM api.interface WHERE id = pId;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.member_interface_add ----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет пользователя или группу к рабочему месту.
 * @param {numeric} pMember - Идентификатор пользователя/группы
 * @param {numeric} pInterface - Идентификатор интерфейса
 * @out param {numeric} result - Результат
 * @out param {text} message - Текст ошибки
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.member_interface_add (
  pMember       numeric,
  pInterface	numeric
) RETURNS       void
AS $$
BEGIN
  PERFORM AddMemberToInterface(pMember, pInterface);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.member_interface_delete -------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Удаляет интерфейс для пользователя или группу.
 * @param {numeric} pMember - Идентификатор пользователя/группы
 * @param {numeric} pInterface - Идентификатор интерфейса, при null удаляет все рабочие места для указанного пользователя
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.member_interface_delete (
  pMember       numeric,
  pInterface	numeric
) RETURNS       void
AS $$
BEGIN
  PERFORM DeleteInterfaceForMember(pMember, pInterface);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.interface_member_delete -------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Удаляет пользователя или группу из интерфейса.
 * @param {numeric} pInterface - Идентификатор интерфейса
 * @param {numeric} pMember - Идентификатор пользователя/группы, при null удаляет всех пользователей из указанного интерфейса
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.interface_member_delete (
  pInterface	numeric,
  pMember       numeric DEFAULT null
) RETURNS       void
AS $$
BEGIN
  PERFORM DeleteMemberFromInterface(pInterface, pMember);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.member_interface --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.member_interface
AS
  SELECT * FROM MemberInterface;

GRANT SELECT ON api.member_interface TO daemon;

--------------------------------------------------------------------------------
-- api.interface_member --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список участников интерфейса.
 * @return {SETOF record} - Запись
 */
CREATE OR REPLACE FUNCTION api.interface_member (
  pInterfaceId  numeric
) RETURNS TABLE (
  id            numeric,
  type          char,
  username      varchar,
  name          text,
  email         text,
  description   text,
  status        text,
  system        text
)
AS $$
  SELECT g.id, 'G' AS type, g.username, g.name, null AS email, g.description, null AS status, g.system
    FROM api.member_interface m INNER JOIN groups g ON g.id = m.memberid
   WHERE m.interface = pInterfaceId
  UNION ALL
  SELECT u.id, 'U' AS type, u.username, u.name, u.email, u.description, u.status, u.system
    FROM api.member_interface m INNER JOIN users u ON u.id = m.memberid
   WHERE m.interface = pInterfaceId;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.member_interface --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает рабочее места доступные участнику.
 * @return {record} - Данные интерфейса
 */
CREATE OR REPLACE FUNCTION api.member_interface (
  pUserId   numeric DEFAULT current_userid()
) RETURNS   SETOF api.interface
AS $$
  SELECT *
    FROM api.interface
   WHERE id in (
     SELECT interface FROM db.member_interface WHERE member = (
       SELECT id FROM db.user WHERE id = pUserId
     )
   )
   UNION ALL
  SELECT *
    FROM api.interface
   WHERE id in (
     SELECT interface FROM db.member_interface WHERE member IN (
       SELECT userid FROM db.member_group WHERE member = (
         SELECT id FROM db.user WHERE id = pUserId
       )
     )
   )
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
