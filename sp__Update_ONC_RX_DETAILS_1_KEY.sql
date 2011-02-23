USE [cdomii_dy]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

ALTER Procedure [dbo].[sp__Update_ONC_RX_DETAILS_1_KEY]
AS
-------------------------------------------------------------------------------
-- This stored Procedure is used to update the ONC_RX_DETAILS_1_KEY          --
-- after the updates have already been applied to the FACT2_PATIENT_RX_ONC   --
-- and FACT2_PATIENT_REGIMEN_ONC Tables in Oracle.                           --
-------------------------------------------------------------------------------
BEGIN
	DECLARE @PatientVisitId           INT;
	DECLARE @DiagId                   INT;
	DECLARE @RxId                     INT;
	DECLARE @OncRxDetails1Key         INT;
	DECLARE @PT_RX_ONC_EXISTS         TINYINT; 
	DECLARE @PT_REGMN_ONC_EXISTS      TINYINT; 
		
	DECLARE UpdateList CURSOR 
	FOR SELECT A.PATIENT_VISIT_ONC_ID, A.PATIENT_DIAGNOSIS_ONC_ID, A.PATIENT_DIAGNOSIS_RX_ONC_ID, B.ONC_RX_DETAILS_1_KEY
          FROM IRXTST..ARCHIVE.TEMP_UPD_LINE_OF_THERAPY_CD A INNER JOIN IRXTST..IRX.FACT2_PATIENT_RX_ONC B 
               ON A.PATIENT_VISIT_ONC_ID=B.PATIENT_VISIT_ONC_ID AND A.PATIENT_DIAGNOSIS_ONC_ID = B.PATIENT_DIAGNOSIS_ONC_ID AND A.PATIENT_DIAGNOSIS_RX_ONC_ID=B.PATIENT_DIAGNOSIS_RX_ONC_ID
         ORDER BY A.PATIENT_VISIT_ONC_ID, A.PATIENT_DIAGNOSIS_ONC_ID, A.PATIENT_DIAGNOSIS_RX_ONC_ID 
		FOR READ ONLY;

    SELECT @PT_DIAG_ONC_EXISTS = COUNT(*) FROM information_schema.tables WHERE table_name = 'FACT2_PATIENT_DIAG_ONC'
    SELECT @PT_RX_ONC_EXISTS = COUNT(*) FROM information_schema.tables WHERE table_name = 'FACT2_PATIENT_RX_ONC'
    SELECT @PT_REGMN_ONC_EXISTS = COUNT(*) FROM information_schema.tables WHERE table_name = 'FACT2_PATIENT_DIAG_REGMN_ONC'
	
	OPEN UpdateList;
	FETCH NEXT FROM UpdateList into @PatientVisitId, @DiagId, @OncDiagDetails1Key
	WHILE @@FETCH_STATUS = 0
	BEGIN
		PRINT 'Updating Patient Visit ID:Diag ID' + CHAR(@PatientVisitId) + ' : ' + CHAR(@DiagId)

		IF @PT_DIAG_ONC_EXISTS > 0
		BEGIN
			UPDATE cdomii_dy.dbo.FACT2_PATIENT_DIAG_ONC
			  SET ONC_DIAG_DETAILS_1_KEY = @OncDiagDetails1Key
			WHERE PATIENT_VISIT_ONC_ID = @PatientVisitId AND PATIENT_DIAGNOSIS_ONC_ID = @DiagId
		END
		IF @PT_RX_ONC_EXISTS > 0
		BEGIN
			UPDATE cdomii_dy.dbo.FACT2_PATIENT_RX_ONC
			  SET ONC_DIAG_DETAILS_1_KEY = @OncDiagDetails1Key
			WHERE PATIENT_VISIT_ONC_ID = @PatientVisitId AND PATIENT_DIAGNOSIS_ONC_ID = @DiagId
		END
		IF @PT_REGMN_ONC_EXISTS > 0
		BEGIN
			UPDATE cdomii_dy.dbo.FACT2_PATIENT_DIAG_REGMN_ONC
			  SET ONC_DIAG_DETAILS_1_KEY = @OncDiagDetails1Key
			WHERE PATIENT_VISIT_ONC_ID = @PatientVisitId AND PATIENT_DIAGNOSIS_ONC_ID = @DiagId
		END
		FETCH NEXT FROM UpdateList into @PatientVisitId, @DiagId, @OncDiagDetails1Key
	END
	CLOSE UpdateList;
	DEALLOCATE UpdateList;
END
