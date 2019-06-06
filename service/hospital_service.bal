import daos;
import util;
import ballerina/log;
import ballerina/io;

function reserveAppointment(http:Caller caller, http:Request req, daos:HospitalDAO hospitalDao, string category) {
    var appointmentRequestDetails = req.getJsonPayload();
    if (appointmentRequestDetails is json) {

        daos:Patient patient = {
            name: <string>appointmentRequestDetails["patient"]["name"],
            dob: <string>appointmentRequestDetails["patient"]["dob"],
            ssn: <string>appointmentRequestDetails["patient"]["ssn"],
            address: <string>appointmentRequestDetails["patient"]["address"],
            phone: <string>appointmentRequestDetails["patient"]["phone"],
            email: <string>appointmentRequestDetails["patient"]["email"]
        };

        daos:AppointmentRequest appointmentRequest = {
            patient: patient,
            doctor: <string>appointmentRequestDetails["doctor"],
            hospital: <string>appointmentRequestDetails["hospital"],
            appointmentDate: <string>appointmentRequestDetails["appointment_date"]
        };

        if (util:containsStringElement(<string[]>hospitalDao["categories"], category)) {
            var appointment = util:makeNewAppointment(appointmentRequest, hospitalDao);
            if (appointment is daos:Appointment) {
                appointments[string.convert(<int>appointment["appointmentNumber"])] = appointment;
                //add patient to the patient map
                hospitalDao["patientMap"][<string>appointmentRequest["patient"]["ssn"]] = 
                                                                <daos:Patient>appointmentRequest["patient"];
                //add patient to patient record map
                map<daos:PatientRecord> patientRecordMap =  <map<daos:PatientRecord>> hospitalDao["patientRecordMap"];
                //add if patient is not contains in the patient record map
                if (!(util:containsInPatientRecordMap(patientRecordMap, 
                        <string>appointmentRequest["patient"]["ssn"]))) {
                    daos:PatientRecord pr = {
                        patient: <daos:Patient>appointmentRequest["patient"],
                        symptoms: {},
                        treatments: {}
                    };
                    hospitalDao["patientRecordMap"][<string>appointmentRequest["patient"]["ssn"]] = pr;
                }
                var appointmentJson = json.convert(appointment);
                if (appointmentJson is json) {
                    util:sendResponse(caller, appointmentJson);
                } else {
                    log:printError("Error occurred when converting appointment record to JSON.", err = appointmentJson);
                    util:sendResponse(caller, json.convert("Internal error occurred."), 
                                                statusCode = http:INTERNAL_SERVER_ERROR_500);
                }
            } else {
                string doctorNotAvailable = "Doctor " + <string>appointmentRequest["doctor"] + " is not available in " 
                                                                            + <string>appointmentRequest["hospital"];
                log:printInfo("User error when reserving appointment: " + doctorNotAvailable);
                util:sendResponse(caller, json.convert(doctorNotAvailable), statusCode = 400);
            }
        } else {
            string invalidCategory = "Invalid category: " + category;
            log:printInfo("User error when reserving appointment: " + invalidCategory);
            util:sendResponse(caller, json.convert(invalidCategory), statusCode = 400);
        }
    } else {
        util:sendResponse(caller, json.convert("Invalid payload received"), statusCode = 400);
    }
}

function getAppointment(http:Caller caller, http:Request req, int appointmentNo) {
    var appointment = appointments[string.convert(appointmentNo)];
    if (appointment is daos:Appointment) {
        var appointmentJson = json.convert(appointment);
        if (appointmentJson is json) {
            util:sendResponse(caller, appointmentJson);
        } else {
            log:printError("Error occurred when converting appointment record to JSON.", err = appointmentJson);
            util:sendResponse(caller, "Internal error occurred.", statusCode = http:INTERNAL_SERVER_ERROR_500);
        }
    } else {
        log:printInfo("User error in getAppointment: Invalid appointment number: " + appointmentNo);
        util:sendResponse(caller, "Invalid appointment number.", statusCode = 400);
    }
}

function checkChannellingFee(http:Caller caller, http:Request req, int id) {
    if (util:containsAppointmentId(appointments, string.convert(id))) {
        daos:Patient patient = <daos:Patient>appointments[string.convert(id)]["patient"];
        daos:Doctor doctor = <daos:Doctor>appointments[string.convert(id)]["doctor"];

        daos:ChannelingFee channelingFee = {
            patientName: <string>patient["name"],
            doctorName: <string>doctor["name"],
            actualFee: string.convert(<float>doctor["fee"])
        };

        var channelingFeeJson = json.convert(channelingFee);
        if (channelingFeeJson is json) {
            util:sendResponse(caller, channelingFeeJson);
        } else {
            log:printError("Error occurred when converting channelingFee record to JSON.", err = channelingFeeJson);
            util:sendResponse(caller, "Internal error occurred.", statusCode = http:INTERNAL_SERVER_ERROR_500);
        }
    } else {
        log:printInfo("User error in checkChannellingFee: Could not Find the Requested appointment ID: " + id);
        util:sendResponse(caller, "Error. Could not Find the Requested appointment ID.", statusCode = 400);
    }
}

function updatePatientRecord(http:Caller caller, http:Request req, daos:HospitalDAO hospitalDao) {
    var patientDetails = req.getJsonPayload();
    if (patientDetails is json) {
        string ssn = <string>patientDetails["ssn"];
        if ((patientDetails["symptoms"] is json[]) && (patientDetails["treatments"] is json[])) {
            string[] symptoms = util:convertJsonToStringArray(<json[]>patientDetails["symptoms"]);
            string[] treatments = util:convertJsonToStringArray(<json[]>patientDetails["treatments"]);

            var patient = hospitalDao["patientMap"][ssn];
            if (patient is daos:Patient) {
                var patientRecord = hospitalDao["patientRecordMap"][ssn];
                if (patientRecord is daos:PatientRecord) {
                    if (daos:updateSymptomsInPatientRecord(patientRecord, symptoms)
                    && daos:updateTreatmentsInPatientRecord(patientRecord, treatments)) {
                        util:sendResponse(caller, "Record Update Success.");
                    } else {
                        log:printError("Record Update Failed when updating patient record. "
                        + "updateSymptomsInPatientRecord: " 
                        + daos:updateSymptomsInPatientRecord(patientRecord, symptoms)
                        + "updateTreatmentsInPatientRecord: " 
                        + daos:updateTreatmentsInPatientRecord(patientRecord, symptoms));
                        util:sendResponse(caller, "Record Update Failed.", statusCode = http:INTERNAL_SERVER_ERROR_500);
                    }
                } else {
                    log:printInfo("User error when updating patient record: Could not find valid Patient Record.");
                    util:sendResponse(caller, "Could not find valid Patient Record.", statusCode = 400);
                }
            } else {
                log:printInfo("User error when updating patient record: Could not find valid Patient Entry.");
                util:sendResponse(caller, "Could not find valid Patient Entry.", statusCode = 400);
            }
        } else {
            log:printInfo("User error when updating patient record: Invalid payload received.");
            util:sendResponse(caller, "Invalid payload received", statusCode = 400);
        }
    } else {
        log:printInfo("User error when updating patient record: Invalid payload received.");
        util:sendResponse(caller, "Invalid payload received", statusCode = 400);
    }
}

function getPatientRecord(http:Caller caller, http:Request req, daos:HospitalDAO hospitalDao, string ssn) {
    var patientRecord = hospitalDao["patientRecordMap"][ssn];
    if (patientRecord is daos:PatientRecord) {
        var patientRecordJson = json.convert(patientRecord);
        if (patientRecordJson is json) {
            util:sendResponse(caller, patientRecordJson);
        } else {
            log:printError("Error occurred when converting channelingFee record to JSON.", err = patientRecordJson);
            util:sendResponse(caller, "Internal error occurred.", statusCode = http:INTERNAL_SERVER_ERROR_500);
        }
    } else {
        log:printInfo("User error in getPatientRecord: Could not find valid Patient Entry.");
        util:sendResponse(caller, "Could not find valid Patient Entry.", statusCode = 400);
    }
}

function isEligibleForDiscount(http:Caller caller, http:Request req, int id) {
    var appointment = appointments[string.convert(id)];
    if (appointment is daos:Appointment) {
        var eligible = util:checkDiscountEligibility(<string>appointment["patient"]["dob"]);
        if (eligible is boolean) {
            util:sendResponse(caller, eligible);
        } else {
            log:printError("Error occurred when checking discount eligibility.", err = eligible);
            util:sendResponse(caller, "Internal error occurred.", statusCode = http:INTERNAL_SERVER_ERROR_500);
        }
    } else {
        log:printInfo("User error in isEligibleForDiscount: Invalid appointment ID: " + id);
        util:sendResponse(caller, "Invalid appointment ID.", statusCode = 400);
    }
}

function addNewDoctor(http:Caller caller, http:Request req, daos:HospitalDAO hospitalDao) {
    var doctorDetails = req.getJsonPayload();
    if (doctorDetails is json) {
        //if category not exists in hospitalDao categories add it to categories
        string category = <string>doctorDetails["category"];
        if (!(util:containsStringElement(<string[]>hospitalDao["categories"], category))) {
            string[] tempArr = <string[]>hospitalDao["categories"];
            tempArr[tempArr.length()] = category;
            hospitalDao["categories"] = tempArr;
        }

        //add doctor
        var doctor = daos:findDoctorByName(untaint hospitalDao, <string>doctorDetails["name"]);
        if (doctor is daos:Doctor) {
            log:printInfo("User error in addNewDoctor: Doctor Already Exists in the system.");
            util:sendResponse(caller, "Doctor Already Exists in the system.", statusCode = 400);
        } else {
            daos:Doctor doc = {
                name: <string>doctorDetails["name"],
                hospital: <string>doctorDetails["hospital"],
                category: <string>doctorDetails["category"],
                availability: <string>doctorDetails["availability"],
                fee: <float>doctorDetails["fee"]
            };
            hospitalDao["doctorsList"][<int>hospitalDao["doctorsList"].length()] = doc;
            util:sendResponse(caller, "New Doctor Added Successfully.");
        }
    } else {
        log:printInfo("User error when adding a new doctor: Invalid payload received.");
        util:sendResponse(caller, "Invalid payload received", statusCode = 400);
    }
}
