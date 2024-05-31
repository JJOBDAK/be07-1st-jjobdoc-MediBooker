-- 이 프로시저는 의사의 휴무일과 현재의 요일이 겹치지 않으면 데이터를 삽입한다. 
-- waiting_count 값 부여
-- status에 접수 값 default로 부여 

create
    definer = root@`%` procedure InsertRegistration2(IN doctor_id_param int, IN symptom_param varchar(255),
                                                     IN patient_name_param varchar(30),
                                                     IN identity_number_param varchar(20),
                                                     IN patient_phone_param varchar(20), IN address_param varchar(255))
BEGIN
    DECLARE today_day VARCHAR(10);
    DECLARE patient_id_param INT;
    DECLARE last_waiting_count INT;

    -- 현재 요일을 조회한다.
    SET today_day = DAYNAME(NOW());

    -- 기존에 방문한 환자가 있는지 확인한다.
    -- 만약에 기존에 방문한 환자가 존재한다면 기존 데이터를 삽입.
    SELECT patient_id INTO patient_id_param
    FROM Patients
    WHERE identity_number = identity_number_param;

    -- 환자 테이블에 등록된 환자가 업다면 이 환자를 새로운 환자로 등록한다.
    IF patient_id_param IS NULL THEN
        INSERT INTO Patients (patient_name, identity_number, patient_phone, address)
        VALUES (patient_name_param, identity_number_param, patient_phone_param, address_param);
        SET patient_id_param = LAST_INSERT_ID();
    END IF;

    -- 의사의 휴무일과 겹치지 않는 경우에만 접수가 가능하다.
    INSERT INTO Registrations (doctor_id, symptom)
    SELECT doctor_id_param, symptom_param
    FROM Doctors AS d
    JOIN Schedules AS s ON d.doctor_id = s.doctor_id
    WHERE d.doctor_id = doctor_id_param AND s.vacation_date != today_day;

    -- 삽입된 접수의 ID를 조회한다.
    SET @last_inserted_id = LAST_INSERT_ID();

    -- 대기 상태를 추가하고 이 상태의 값은 디폴트로 접수로 지정한다.
    INSERT INTO Waiting (registration_id, patient_id, waiting_count, status, created_time)
    SELECT @last_inserted_id, patient_id_param, COALESCE(MAX(waiting_count), 0) + 1, '접수', NOW()
    FROM Waiting;
END;
