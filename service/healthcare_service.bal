import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/time;
import daos;
import util;

listener http:Listener httpListener = new(9090);

daos:HealthcareDao healthcareDao = {
    doctorsList: [
    { name: "thomas collins", hospital: "grand oak community hospital", category: "surgery", availability: "9.00 a.m - 11.00 a.m", fee: 7000},
    { name: "henry parker", hospital: "grand oak community hospital", category: "ent", availability: "9.00 a.m - 11.00 a.m", fee: 4500},
    { name: "abner jones", hospital: "grand oak community hospital", category: "gynaecology", availability: "8.00 a.m - 10.00 a.m", fee: 11000},
    { name: "abner jones", hospital: "grand oak community hospital", category: "ent", availability: "9.00 a.m - 11.00 a.m", fee: 6750},
    { name: "anne clement", hospital: "clemency medical center", category: "surgery", availability: "9.00 a.m - 11.00 a.m", fee: 12000}
    ],
    catergories: ["surgery", "cardiology", "gynaecology", "ent", "paediatric"],
    payments: {

    }
};

map<daos:Appointment> appointments = {

};

// RESTful service.
@http:ServiceConfig {
    basePath: "/healthcare"
}
service HealthcareService on httpListener {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/{category}"
    }
    resource function reserveAppointment(http:Caller caller, http:Request req, string category) {
        http:Response response = new;
        daos:Doctor[] stock = daos:findDoctorByCategoryFromHealthcareDao(untaint healthcareDao, category);
        var payload = json.convert(stock);
        if (payload is json) {
            response.setJsonPayload(untaint payload);
            sendResponse(caller, response);
        } else {
            response.statusCode = 502;
            response.setPayload("Invalid payload received");
            sendResponse(caller, response);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments/{appointment_id}"
    }
    resource function getAppointment(http:Caller caller, http:Request req, string id) {
        http:Response response = new;
        // HospitalService hospitalService = new;
        daos:Appointment? appointment = appointments[id];
        if (appointment is daos:Appointment) {
            var payload = json.convert(appointment);
            if (payload is json) {
                response.setJsonPayload(untaint payload);
                sendResponse(caller, response);
            } else {
                response.statusCode = 502;
                response.setPayload("Invalid payload received");
                sendResponse(caller, response);
            }
        } else {
            string payload = "Error. There is no appointment with appointment number " + id;
            response.setPayload(untaint payload);
            sendResponse(caller, response);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments/validity/{appointment_id}"
    }
    resource function getAppointmentValidityTime(http:Caller caller, http:Request req, string id) {
        http:Response response = new;
        // HospitalService hospitalService = new;
        // daos:Appointment? appointment = hospitalService.getAppointments()[id];
        daos:Appointment? appointment = appointments[id];
        int diffDays = 0;
        if (appointment is daos:Appointment) {
            var date = time:parse(<string>appointment["time"], "yyyy-MM-dd");
            if (date is time:Time) {
                time:Time today = time:currentTime();
                diffDays = (date.time - today.time) / (24 * 60 * 60 * 1000);
                response.setJsonPayload(untaint diffDays);
                sendResponse(caller, response);
            } else {
                string payload = "Error. Invalid date for appointment number " + id;
                response.setPayload(untaint payload);
                sendResponse(caller, response);
            }
        } else {
            string payload = "Error. There is no appointment with appointment number " + id;
            response.setPayload(untaint payload);
            sendResponse(caller, response);
        }
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/appointments/{appointment_id}"
    }
    resource function removeAppointment(http:Caller caller, http:Request req, string id) {
        http:Response response = new;
        // HospitalService hospitalService = new;
        string payload;
        // if (hospitalService.getAppointments().remove(id)) {
        if (appointments.remove(id)) {
            payload = "Appointment is successfully removed";
        } else {
            payload = "Error. Failed to remove appoitment with appointment number " + id;
        }
        response.setPayload(untaint payload);
        sendResponse(caller, response);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/payments"
    }
    resource function settlePayment(http:Caller caller, http:Request req) returns error? {
        http:Response response = new;
        string payload;
        var paymentSettlementDetails = req.getJsonPayload();
        if (paymentSettlementDetails is json) {
            daos:PaymentSettlement paymentSettlement = {
                appointmentNumber: <int>paymentSettlementDetails["appointmentNumber"],
                doctor: {
                    name: <string>paymentSettlementDetails["doctor"]["name"],
                    hospital: <string>paymentSettlementDetails["doctor"]["hospital"],
                    category: <string>paymentSettlementDetails["doctor"]["category"],
                    availability: <string>paymentSettlementDetails["doctor"]["availability"],
                    fee: <float>paymentSettlementDetails["doctor"]["fee"]
                },
                patient: {
                    name: <string>paymentSettlementDetails["patient"]["name"],
                    dob: <string>paymentSettlementDetails["patient"]["dob"],
                    ssn: <string>paymentSettlementDetails["patient"]["ssn"],
                    address: <string>paymentSettlementDetails["patient"]["address"],
                    phone: <string>paymentSettlementDetails["patient"]["phone"],
                    email: <string>paymentSettlementDetails["patient"]["email"]
                },
                fee: <float>paymentSettlementDetails["fee"],
                confirmed: <boolean>paymentSettlementDetails["confirmed"],
                cardNumber: <string>paymentSettlementDetails["cardNumber"]
            };

            if (<int>paymentSettlement["appointmentNumber"] >= 0) {
                daos:Payment payment = check util:createNewPaymentEntry(paymentSettlement, untaint healthcareDao);
                payment["status"] = "Settled";
                healthcareDao["payments"][<string>payment["paymentID"]] = untaint payment;
                payload = "Settled payment successfully with payment ID: " + <string>payment["paymentID"];
            } else {
                payload = "Error. Could not Find the Requested appointment ID.";
            }
            response.setPayload(untaint payload);
            sendResponse(caller, response);
        } else {
            response.statusCode = 400;
            response.setPayload("Invalid payload received");
            sendResponse(caller, response);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/payments/payment/{payment_id}"
    }
    resource function getPaymentDetails(http:Caller caller, http:Request req, string paymentId) returns error? {
        json payload;
        http:Response response = new;
        var payment = healthcareDao["payments"][paymentId];
        if (payment is daos:Payment) {
            payload = check json.convert(payment);
        } else {
            payload = json.convert("Invalid payment id provided");
        }
        response.setPayload(untaint payload);
        sendResponse(caller, response);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/admin/newdoctor"
    }
    resource function addNewDoctor(http:Caller caller, http:Request req) returns error? {
        json payload;
        http:Response response = new;
        var doctorDetails = req.getJsonPayload();
        if (doctorDetails is json) {
            string category = <string>doctorDetails["category"];
            if (!util:containsStringElement(<string[]>healthcareDao["categories"], category)) {
                string[] a = <string[]>healthcareDao["categories"];
                a[a.length()] = category;
                healthcareDao["categories"] = a;
            }
            var doctor = daos:findDoctorByNameFromHelathcareDao(untaint healthcareDao, <string>doctorDetails["name"]);
            if (doctor is daos:Doctor) {
                daos:Doctor doc = {
                    name: <string>doctorDetails["name"],
                    hospital: <string>doctorDetails["hospital"],
                    category: <string>doctorDetails["category"],
                    availability: <string>doctorDetails["availability"],
                    fee: <float>doctorDetails["fee"]
                };
                healthcareDao["doctorsList"][<int>healthcareDao["doctorsList"].length()] = doc;
                payload = json.convert("New Doctor Added Successfully");
            } else {
                payload = json.convert("Doctor Already Exist in the system");
            }
            response.setPayload(payload);
            sendResponse(caller, response);
        } else {
            response.statusCode = 400;
            response.setPayload("Invalid payload received");
            sendResponse(caller, response);
        }
    }
}

function sendResponse(http:Caller caller, http:Response response) {
    var result = caller->respond(response);
    if (result is error) {
        log:printError("Error sending response", err = result);
    }
}
