-- TRIGGER 1: CONTROLLO STIPENDIO OCULISTA
CREATE OR REPLACE TRIGGER ContrStipOculista
BEFORE INSERT OR UPDATE OF Stipendio ON Contratto 
FOR EACH ROW 
DECLARE
mat_oc  		Oculista.matricola_oculista%type;
err_oc_pt		EXCEPTION;
err_oc_ft		EXCEPTION;
err_gc_pt		EXCEPTION;
err_gc_ft		EXCEPTION;
err_gf_pt		EXCEPTION;
err_gf_ft		EXCEPTION;
err_mag_pt		EXCEPTION;
err_mag_ft		EXCEPTION;
BEGIN
SELECT Matricola_oculista INTO mat_oc
FROM OCULISTA
WHERE Matricola_oculista=:NEW.Matricola_dipendente;
IF (:NEW.Durata='PART-TIME') AND (:NEW.Stipendio < 1000 OR :NEW.Stipendio > 1500) AND (:New.Matricola_dipendente=mat_oc) 
THEN RAISE err_oc_pt; 
ELSE IF (:NEW.Durata='FULL-TIME') AND (:NEW.Stipendio < 1500 OR :NEW.Stipendio > 2000) AND (:New.Matricola_dipendente=mat_oc)
THEN RAISE err_oc_ft;
END IF;
END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN NULL;
WHEN err_oc_pt THEN RAISE_APPLICATION_ERROR (-20325, 'Stipendio per oculista part-time non valido, inserire un valore tra 1000 e 1500.');
WHEN err_oc_ft THEN  RAISE_APPLICATION_ERROR (-20326, 'Stipendio per oculista full-time non valido, inserire un valore tra 1500 e 2000.');
END;
/

-- TRIGGER 2: CONTROLLO STIPENDIO IMPIEGATO
CREATE OR REPLACE TRIGGER ContrStipImpiegato 
BEFORE INSERT OR UPDATE OF Stipendio ON Contratto 
FOR EACH ROW 
DECLARE
mans 			Impiegato.Mansione%type;
err_oc_pt		EXCEPTION;
err_oc_ft		EXCEPTION;
err_gc_pt		EXCEPTION;
err_gc_ft		EXCEPTION;
err_gf_pt		EXCEPTION;
err_gf_ft		EXCEPTION;
err_mag_pt		EXCEPTION;
err_mag_ft		EXCEPTION;
BEGIN
SELECT MANSIONE INTO mans
FROM IMPIEGATO
WHERE MATRICOLA_IMP=:NEW.MATRICOLA_DIPENDENTE;
IF (:NEW.Durata='PART-TIME') AND (mans='GESTORE_DEI_CLIENTI') AND (:NEW.Stipendio < 800 OR :NEW.Stipendio > 1300) 
THEN RAISE err_gc_pt;
ELSE IF (:NEW.Durata='FULL-TIME') AND (mans='GESTORE_DEI_CLIENTI') AND (:NEW.Stipendio < 1300 OR :NEW.Stipendio > 1800) 
THEN RAISE err_gc_ft; 
ELSE IF (:New.Durata='PART-TIME') AND (mans='GESTORE_DEI_FORNITORI') AND (:NEW.Stipendio < 900 OR :NEW.Stipendio > 1400)
THEN RAISE err_gf_pt; 
ELSE IF (:New.Durata='FULL-TIME') AND (mans='GESTORE_DEI_FORNITORI') AND (:NEW.Stipendio < 1400 OR :NEW.Stipendio > 1900)
THEN RAISE err_gf_ft; 
ELSE IF (:New.Durata='PART-TIME') AND (mans='MAGAZZINIERE') AND (:NEW.Stipendio < 700 OR :NEW.Stipendio > 1200)
THEN RAISE err_mag_pt; 
ELSE IF (:New.Durata= 'FULL-TIME') AND (mans='MAGAZZINIERE') AND (:NEW.Stipendio < 1200 OR :NEW.Stipendio > 1700)
THEN RAISE err_mag_ft; 
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN NULL;
WHEN err_gc_pt THEN RAISE_APPLICATION_ERROR (-20327, 'Stipendio non valido per i gestori dei clienti part-time, inserire un valore tra 800 e 1300');
WHEN err_gc_ft THEN RAISE_APPLICATION_ERROR (-20328, 'Stipendio non valido per i gestori dei clienti full-time, inserire un valore tra 1300 e 1800.');
WHEN err_gf_pt THEN RAISE_APPLICATION_ERROR (-20329, 'Stipendio non valido per i gestori dei fornitori part-time, inserire un valore tra 900 e 1400.');
WHEN err_gf_ft THEN RAISE_APPLICATION_ERROR (-20330, 'Stipendio non valido per i gestori dei fornitori full-time, inserire un valore tra 1400 e 1900.');
WHEN err_mag_pt THEN RAISE_APPLICATION_ERROR (-20331, 'Stipendio non valido per i magazzinieri part-time, inserire un valore tra 700 e 1200.');
WHEN err_mag_ft THEN RAISE_APPLICATION_ERROR (-20332, 'Stipendio non valido per i magazzinieri part-time, inserire un valore tra 1200 e 1700.');
END;
/

-- TRIGGER 3: CONTROLLO SCORTE MAGAZZINO
CREATE OR REPLACE TRIGGER ContrScorte
BEFORE INSERT OR UPDATE ON Include
FOR EACH ROW
DECLARE
totale 		number;
tot_agg 		number;
inserimento_max 	number;
quant_mag 		number;
quant_trasp 		number;
mag_qpieno 		EXCEPTION;
cap_max 		EXCEPTION;
mag_pieno 		EXCEPTION;
ins_parziale 		EXCEPTION;
BEGIN
SELECT SUM(i.quantita_acquistata) into quant_mag
FROM fornitura f join include i on (f.codice_fornitura=i.codice_forn)
WHERE f.data_ora_arrivo < to_char(sysdate, 'dd/mon/yyyy');
SELECT SUM(e.quantita_trasportata) into quant_trasp
FROM e_incluso e
WHERE e.data_app < to_char(sysdate, 'dd/mon/yyyy');
totale:=quant_mag-quant_trasp;
tot_agg := totale + :new.quantita_acquistata;
IF (totale = 1000) THEN
RAISE mag_pieno;
END IF;
IF (tot_agg >= 900 AND tot_agg < 1000) THEN 
RAISE mag_qpieno;
END IF;
IF (tot_agg = 1000) THEN 
RAISE cap_max;
ELSE IF (tot_agg > 1000) THEN
inserimento_max := 1000 - totale;
:NEW.quantita_acquistata := inserimento_max;
RAISE ins_parziale;
END IF;
END IF;
EXCEPTION
WHEN mag_pieno THEN RAISE_APPLICATION_ERROR (-20330, 'Attenzione! Magazzino pieno. Impossibile aggiungere nuove forniture!');
WHEN mag_qpieno THEN DBMS_OUTPUT.PUT_LINE('Attenzione! Magazzino quasi pieno!');
WHEN cap_max THEN DBMS_OUTPUT.PUT_LINE('Attenzione! Con questa nuova fornitura e'' stata raggiunta la capacita'' massima del magazzino.');
WHEN ins_parziale THEN DBMS_OUTPUT.PUT_LINE ('Attenzione! E'' stato possibile inserire solo una quantita'' pari a '||inserimento_max||' in quanto il magazzino ha raggiunto la sua capacita'' massima.');
END;
/

-- TRIGGER 4: CONTROLLO APPROVVIGIONAMENTI
CREATE OR REPLACE TRIGGER ContrScorte2 
BEFORE INSERT OR UPDATE ON E_incluso 
FOR EACH ROW 
DECLARE
totale 	number;
totale_agg 	number;
mag_qvuoto 	EXCEPTION;
mag_vuoto 	EXCEPTION;
mag_vuoto2 	EXCEPTION;
mag_neg 	EXCEPTION;
BEGIN 
SELECT (		(SELECT SUM(i.quantita_acquistata)
			FROM fornitura f join include i on f.codice_fornitura=i.codice_forn
			WHERE i.codice_prodotto = :new.codice_a_barre_prod AND f.data_ora_arrivo < to_char(sysdate, 'dd/mon/yyyy'))
			-
			(SELECT SUM(e.quantita_trasportata)
			FROM e_incluso e 
			WHERE codice_a_barre_prod= :new.codice_a_barre_prod )
	)INTO totale
FROM DUAL;
totale_agg:= totale - :NEW.quantita_trasportata;
IF (totale = 0) THEN
RAISE mag_vuoto;
END IF;
IF (totale_agg > 0 AND totale_agg < 200) THEN
RAISE mag_qvuoto;
END IF;
IF (totale_agg = 0) THEN 
RAISE mag_vuoto2;
END IF;
IF (totale_agg < 0) THEN
RAISE mag_neg;
END IF;
EXCEPTION
WHEN mag_vuoto THEN RAISE_APPLICATION_ERROR (-20334, 'Attenzione! Scorte per questo prodotto finite! Impossibile inviare nuovi approvvigionamenti. ASPETTARE LA PROSSIMA FORNITURA O FISSARNE UNA NUOVA!');
WHEN mag_qvuoto THEN DBMS_OUTPUT.PUT_LINE('Attenzione! Scorte per questo prodotto quasi finite!');
WHEN mag_vuoto2 THEN DBMS_OUTPUT.PUT_LINE('Attenzione! Le quantita'' per questo prodotto sono finite. Non sara'' più'' possibile inviare altri approvvigionamenti.');
WHEN mag_neg THEN RAISE_APPLICATION_ERROR (-20335, 'Attenzione! Il magazzino non contiene la quantita'' di prodotti desiderata.');
END;
/

-- TRIGGER 5: CONTROLLO VISITE NO SABATO, DOMENICA, PARI
CREATE OR REPLACE TRIGGER CHECK_VISITE
BEFORE INSERT OR UPDATE ON VISITA_OCULISTICA_EFFETTUATA 
FOR EACH ROW
DECLARE
GIORNO        DATE;
NO_SABATO 	EXCEPTION;
NO_DOMENICA 	EXCEPTION;
NO_PARI 	EXCEPTION;
BEGIN
GIORNO := :NEW.DATA_ORA_INIZIO;
IF TO_CHAR(GIORNO,'D')=6 THEN 
RAISE NO_SABATO;
ELSE IF TO_CHAR(GIORNO,'D')=7 THEN
RAISE NO_DOMENICA;
ELSE IF TO_CHAR(GIORNO,'D')=2 OR TO_CHAR(GIORNO,'D')=4 THEN
RAISE NO_PARI;
END IF;
END IF;
END IF;
EXCEPTION 
WHEN NO_SABATO THEN
RAISE_APPLICATION_ERROR(-20337, 'Attenzione! Non si possono effettuare visite il sabato! Inserire un''altra data.');
WHEN NO_DOMENICA THEN
RAISE_APPLICATION_ERROR(-20338, 'Attenzione! Non si possono effettuare visite la domenica! Inserire un''altra data.'); 
WHEN NO_PARI THEN
RAISE_APPLICATION_ERROR(-20339, 'Attenzione! Non si possono effettuare visite nei giorni pari! Inserire un''altra data.');
END;
/

-- TRIGGER 6: CONTROLLO CONSEGNE NO SABATO, DOMENICA
CREATE OR REPLACE TRIGGER CHECK_CONSEGNA
BEFORE INSERT ON CONSEGNA
FOR EACH ROW
DECLARE
NO_SABATO 	EXCEPTION;
NO_DOMENICA 	EXCEPTION;
BEGIN 
IF TO_CHAR(:NEW.DATA_CONSEGNA,'D')=6 THEN 
RAISE NO_SABATO;
ELSE IF TO_CHAR(:NEW.DATA_CONSEGNA,'D')=7 THEN
RAISE NO_DOMENICA;
END IF;
END IF;
EXCEPTION 
WHEN NO_SABATO THEN
:NEW.DATA_CONSEGNA:=:NEW.DATA_CONSEGNA+2;
DBMS_OUTPUT.PUT_LINE('Attenzione! Non si possono effettuare consegne il sabato! La consegna e'' stata automaticamente spostata a lunedi''.'); 
WHEN NO_DOMENICA THEN
:NEW.DATA_CONSEGNA:=:NEW.DATA_CONSEGNA+1;
DBMS_OUTPUT.PUT_LINE('Attenzione! Non si possono effettuare consegne la domenica! La consegna e'' stata automaticamente spostata a lunedi''.');  
END;
/

-- TRIGGER 7: CONTROLLO ETA' DIPENDENTE
CREATE OR REPLACE TRIGGER CheckEta
BEFORE INSERT OR UPDATE ON Contratto
FOR EACH ROW 
DECLARE
DataNascita		DATE;
Diff_Mesi 		number;
DATA_ERRATA		EXCEPTION;
BEGIN 
SELECT DATA_NASCITA INTO DataNascita 
FROM DIPENDENTE
WHERE matricola=:new.matricola_dipendente;
Diff_mesi := MONTHS_BETWEEN(:New.Data_Assunzione, DataNascita);
IF (Diff_mesi < 216) THEN 
RAISE DATA_ERRATA;
END IF;
EXCEPTION
WHEN DATA_ERRATA THEN 
RAISE_APPLICATION_ERROR (-20342, 'Data inserita non valida, la persona non raggiunge la maggiore eta'' entro la data dell''assunzione.');
END;
/

-- TRIGGER 8: CONTROLLO NUMERO DIPENDENTI PER LICENZIAMENTO
CREATE OR REPLACE TRIGGER Licenziamento
INSTEAD OF DELETE ON vw_Dipendente
FOR EACH ROW
DECLARE
NumImp        INTEGER;
NumOcu        INTEGER;
NumQMin       Exception;
NumMin        Exception;
NumOcMin 	Exception;
BEGIN
SELECT COUNT(I.Matricola_imp) INTO NumImp
FROM ((Punto_Vendita P JOIN Dipendente D ON P.Citta=D.Citta_PV) JOIN Impiegato I ON D.Matricola=I.Matricola_imp)
WHERE D.Citta_PV=:OLD.Citta_PV;
SELECT COUNT(O.Matricola_Oculista) INTO NumOcu
FROM ((Punto_Vendita P JOIN Dipendente D ON P.Citta=D.Citta_PV) JOIN Oculista O ON D.Matricola=O.Matricola_Oculista)
WHERE D.Citta_PV=:OLD.Citta_PV;
IF (NumImp=4)
THEN
RAISE NumQMin;
ELSE IF (NumImp=3) THEN
RAISE NumMin;
ELSE IF(NumOcu=1)  THEN
RAISE NumOcMin;
END IF;
END IF;
END IF;
EXCEPTION
WHEN NumQMin THEN
DBMS_OUTPUT.PUT_LINE('Attenzione! Si e'' quasi raggiunto il numero minimo di impiegati per punto vendita!');
DELETE FROM Dipendente WHERE Matricola = :OLD.Matricola;
WHEN NumMin THEN
RAISE_APPLICATION_ERROR (-20343, 'Si e'' raggiunto il numero minimo di impiegati, procedere all''assunzione di nuovo organico.');
WHEN NumOcMin THEN
RAISE_APPLICATION_ERROR (-20344, 'Prima di licenziare l''unico oculista accertarsi di averne assunto un altro!');
END;
/

-- TRIGGER 9: CONTROLLO ASSEGNAZIONE TURNO
CREATE OR REPLACE TRIGGER ContrTurno
BEFORE INSERT OR UPDATE ON Rispetta
FOR EACH ROW
DECLARE
conta_contr		NUMBER;
dur                 	Contratto.Durata%type;
err_turno_oc_pt   	EXCEPTION;
err_turno_oc_ft     	EXCEPTION;
err_turno_imp_pt    	EXCEPTION;
err_turno_imp_ft    	EXCEPTION;
BEGIN
SELECT COUNT(*) INTO conta_contr
FROM CONTRATTO
WHERE MATRICOLA_DIPENDENTE = :NEW.MATRICOLA_DIP;
IF conta_contr > 1 THEN
SELECT DURATA INTO dur
FROM CONTRATTO
WHERE MATRICOLA_DIPENDENTE=:NEW.MATRICOLA_DIP AND DATA_ASSUNZIONE = (SELECT MAX(DATA_ASSUNZIONE)
										FROM CONTRATTO
										WHERE MATRICOLA_DIPENDENTE = :NEW.MATRICOLA_DIP AND DATA_ASSUNZIONE < SYSDATE);
ELSE IF conta_contr = 1 THEN
SELECT DURATA INTO dur
FROM CONTRATTO
WHERE MATRICOLA_DIPENDENTE=:NEW.MATRICOLA_DIP;
END IF;
END IF;
IF (:NEW.Cod_turno='TURNOOCPT1' OR :NEW.Cod_turno='TURNOOCPT2') AND (dur='FULL-TIME')
THEN RAISE err_turno_oc_pt;
END IF;
IF (:NEW.Cod_turno='TURNOOCFT') AND (dur='PART-TIME')
THEN RAISE err_turno_oc_ft;
END IF;
IF (:NEW.Cod_turno='TURNOIMPPT1' OR :NEW.Cod_turno='TURNOIMPPT2') AND (dur='FULL_TIME')
THEN RAISE err_turno_imp_pt;
END IF;
IF (:NEW.Cod_turno='TURNOIMPFT') AND (dur='PART-TIME')
THEN RAISE err_turno_imp_ft;
END IF;
EXCEPTION
WHEN err_turno_oc_pt THEN RAISE_APPLICATION_ERROR (-20350, 'Il turno che si vuole assegnare all''oculista non corrisponde al tipo di contratto "FULL-TIME".');
WHEN err_turno_oc_ft THEN RAISE_APPLICATION_ERROR (-20351, 'Il turno che si vuole assegnare all''oculista non corrisponde al tipo di contratto "PART-TIME".');
WHEN err_turno_imp_pt THEN RAISE_APPLICATION_ERROR (-20352, 'Il turno che si vuole assegnare all''impiegato non corrisponde al tipo di contratto "FULL-TIME".');
WHEN err_turno_imp_ft THEN RAISE_APPLICATION_ERROR (-20353, 'Il turno che si vuole assegnare all''impiegato non corrisponde al tipo di contratto "PART-TIME".');
END;
/