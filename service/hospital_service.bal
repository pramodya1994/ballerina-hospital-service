import daos;
import util;
import ballerina/log;
import ballerina/io;

function reserveAppointment(http:Caller caller, http:Request req, daos:HospitalDAO hospitalDao, string category) {
    http:Response response = new;
    json payload;
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
                hospitalDao["patientMap"][<string>appointmentRequest["patient"]["ssn"]] = <daos:Patient>appointmentRequest["patient"];
                //add patient to patient record map
                map<daos:PatientRecord> patientRecordMap =  <map<daos:PatientRecord>> hospitalDao["patientRecordMap"];
                //add if patient is not contains in the patient record map
                if (!(util:containsInPatientRecordMap(patientRecordMap, <string>appointmentRequest["patient"]["ssn"]))) {
                    daos:PatientRecord pr = {
                        patient: <daos:Patient>appointmentRequest["patient"],
                        symptoms: {

                        },
                        treatments: {

                        }
                    };
                    hospitalDao["patientRecordMap"][<string>appointmentRequest["patient"]["ssn"]] = pr;
                }
                var appointmentJson = json.convert(appointment);
                if (appointmentJson is json) {
                    payload = appointmentJson;
                } else {
                    log:printError("Error occurred when converting appointment record to JSON.", err = appointmentJson);
                    response.statusCode = 500;
                    payload = json.convert("Internal error occurred.");
                }
            } else {
                payload = json.convert("Doctor " + <string>appointmentRequest["doctor"] + " is not available in " + <string>appointmentRequest["hospital"]);
            }
        } else {
            payload = json.convert("Invalid Category");
        }
        response.setPayload(untaint payload);
        sendResponse(caller, response);
    } else {
        response.statusCode = 400;
        response.setPayload("Invalid payload received");
        sendResponse(caller, response);
    }
}

function getAppointment(http:Caller caller, http:Request req, int appointmentNo) {
    http:Response response = new;
    json payload;
    var appointment = appointments[string.convert(appointmentNo)];
    if (appointment is daos:Appointment) {
        var appointmentJson = json.convert(appointment);
        if (appointmentJson is json) {
            payload = appointmentJson;
        } else {
            log:printError("Error occurred when converting appointment record to JSON.", err = appointmentJson);
            response.statusCode = 500;
            payload = json.convert("Internal error occurred.");
        }
    } else {
        payload = json.convert("Invalid appointment number.");
    }
    response.setPayload(untaint payload);
    sendResponse(caller, response);
}

function checkChannellingFee(http:Caller caller, http:Request req, int id) {
    http:Response response = new;
    json payload;
    if (containsAppointmentId(appointments, string.convert(id))) {
        daos:Patient patient = <daos:Patient>appointments[string.convert(id)]["patient"];
        daos:Doctor doctor = <daos:Doctor>appointments[string.convert(id)]["doctor"];

        daos:ChannelingFee channelingFee = {
            patientName: <string>patient["name"],
            doctorName: <string>doctor["name"],
            actualFee: string.convert(<float>doctor["fee"])
        };
        var channelingFeeJson = json.convert(channelingFee);
        if (channelingFeeJson is json) {
            payload = channelingFeeJson;
        } else {
            log:printError("Error occurred when converting channelingFee record to JSON.", err = channelingFeeJson);
            response.statusCode = http:INTERNAL_SERVER_ERROR_500;
            payload = json.convert("Internal error occurred.");
        }
    } else {
        response.statusCode = 400;
        payload = json.convert("Error. Could not Find the Requested appointment ID.");
    }
    response.setPayload(untaint payload);
    sendResponse(caller, response);
}

function updatePatientRecord(http:Caller caller, http:Request req, daos:HospitalDAO hospitalDao) {
    http:Response response = new;
    json payload;
    var patientDetails = req.getJsonPayload();
    // io:println(patientDetails);
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
                        payload = "Record Update Success.";
                    } else {
                        payload = "Record Update Failed.";
                    }
                } else {
                    payload = "Could not find valid Patient Record.";
                }
            } else {
                payload = json.convert("Could not find valid Patient Entry.");
            }
            response.setPayload(untaint payload);
            sendResponse(caller, response);
        } else {
            response.statusCode = 400;
            response.setPayload("Invalid payload received");
            sendResponse(caller, response);
        }
    } else {
        response.statusCode = 400;
        response.setPayload("Invalid payload received");
        sendResponse(caller, response);
    }
}

function getPatientRecord(http:Caller caller, http:Request req, daos:HospitalDAO hospitalDao, string ssn) {
    http:Response response = new;
    json payload;
    var patientRecord = hospitalDao["patientRecordMap"][ssn];
    if (patientRecord is daos:PatientRecord) {
        var patientRecordJson = json.convert(patientRecord);
        if (patientRecordJson is json) {
            payload = patientRecordJson;
        } else {
            log:printError("Error occurred when converting channelingFee record to JSON.", err = patientRecordJson);
            response.statusCode = 500;
            payload = json.convert("Internal error occurred.");
        }
    } else {
        payload = json.convert("Could not find valid Patient Entry.");
    }
    response.setPayload(untaint payload);
    sendResponse(caller, response);
}

function isEligibleForDiscount(http:Caller caller, http:Request req, int id) {
    http:Response response = new;
    json payload;
    var appointment = appointments[string.convert(id)];
    if (appointment is daos:Appointment) {
        var eligible = util:checkDiscountEligibility(<string>appointment["patient"]["dob"]);
        if (eligible is boolean) {
            payload = json.convert(eligible);
        } else {
            payload = json.convert("Error occurred when checking discount eligibility.");
        }
    } else {
        payload = json.convert("Invalid appointment ID.");
    }
    response.setPayload(untaint payload);
    sendResponse(caller, response);
}

function addNewDoctor(http:Caller caller, http:Request req, daos:HospitalDAO hospitalDao) {
    http:Response response = new;
    json payload;
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
            payload = json.convert("Doctor Already Exists in the system.");
        } else {
            daos:Doctor doc = {
                name: <string>doctorDetails["name"],
                hospital: <string>doctorDetails["hospital"],
                category: <string>doctorDetails["category"],
                availability: <string>doctorDetails["availability"],
                fee: <float>doctorDetails["fee"]
            };
            hospitalDao["doctorsList"][<int>hospitalDao["doctorsList"].length()] = doc;
            payload = json.convert("New Doctor Added Successfully.");
        }
        response.setPayload(untaint payload);
        sendResponse(caller, response);
    } else {
        response.statusCode = 400;
        response.setPayload("Invalid payload received.");
        sendResponse(caller, response);
    }
}

function containsAppointmentId(map<daos:Appointment> appointmentsMap, string id) returns boolean {
    foreach (string, daos:Appointment) (k, v) in appointmentsMap {
        if (k.equalsIgnoreCase(id)) {
            return true;
        }
    }
    return false;
}
