import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/time;
import daos;
import util;

listener http:Listener httpListener = new(9090);

@http:ServiceConfig {
    basePath: "/healthcare"
}
service HealthcareService on httpListener {

    ClemencyHospitalService clemency = new;
    GrandOakHospitalService grandoaks = new;
    PineValleyHospitalService pinevalley = new;
    WillowGardensHospitalService willowgarden = new;

    daos:HealthcareDao healthcareDao = {
        doctorsList: [
            clemency.doctor1, 
            clemency.doctor2, 
            clemency.doctor3,
            grandoaks.doctor1, 
            grandoaks.doctor2, 
            grandoaks.doctor3,
            grandoaks.doctor4, 
            pinevalley.doctor1, 
            pinevalley.doctor2,
            willowgarden.doctor1, 
            willowgarden.doctor2
        ],
        categories: ["surgery", "cardiology", "gynaecology", "ent", "paediatric"],
        payments: {}
    };

    map<daos:Appointment> appointments = {};

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/{category}"
    }
    resource function reserveAppointment(http:Caller caller, http:Request req, string category) {
        http:Response response = new;
        daos:Doctor[] stock = daos:findDoctorByCategoryFromHealthcareDao(self.healthcareDao, category);
        if(stock.length() > 0) {
            var payload = json.convert(stock);
            if (payload is json) {
                util:sendResponse(caller, payload);
            } else {
                log:printError("Error occurred when converting appointment record to JSON.", err = payload);
                util:sendResponse(caller, json.convert("Internal error occurred."), 
                                                    statusCode = http:INTERNAL_SERVER_ERROR_500);
            }
        } else {
            util:sendResponse(caller, "Could not find any entry for the requested Category");
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments/{appointmentId}"
    }
    resource function getAppointment(http:Caller caller, http:Request req, int appointmentId) {
        daos:Appointment? appointment = self.appointments[string.convert(appointmentId)];
        if (appointment is daos:Appointment) {
            var payload = json.convert(appointment);
            if (payload is json) {
                util:sendResponse(caller, payload);
            } else {
                log:printError("Error occurred when converting appointment record to JSON.", err = payload);
                util:sendResponse(caller, json.convert("Internal error occurred."), 
                                                    statusCode = http:INTERNAL_SERVER_ERROR_500);
            }
        } else {
            log:printInfo("User error in getAppointment: There is no appointment with appointment number " 
                                + appointmentId);
            util:sendResponse(caller, "Error. There is no appointment with appointment number " + appointmentId, 
                                statusCode = 400);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments/validity/{appointmentId}"
    }
    resource function getAppointmentValidityTime(http:Caller caller, http:Request req, string appointmentId) {
        daos:Appointment? appointment = self.appointments[appointmentId];
        int diffDays = 0;
        if (appointment is daos:Appointment) {
            var date = time:parse(<string>appointment["appointmentDate"], "yyyy-MM-dd");
            if (date is time:Time) {
                time:Time today = time:currentTime();
                diffDays = (date.time - today.time) / (24 * 60 * 60 * 1000);
                util:sendResponse(caller, diffDays);
            } else {
                log:printError("Invalid date in the appointent with ID: " + appointmentId, err = date);
                util:sendResponse(caller, "Internal error occurred.", statusCode = http:INTERNAL_SERVER_ERROR_500);
            }
        } else {
            log:printInfo("User error in getAppointment: There is no appointment with appointment number " 
                                + appointmentId);
            util:sendResponse(caller, "Error.Could not Find the Requested appointment ID", statusCode = 400);
        }
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/appointments/{appointmentId}"
    }
    resource function removeAppointment(http:Caller caller, http:Request req, string appointmentId) {
        if(self.appointments.remove(appointmentId)) {
            util:sendResponse(caller, "Appointment is successfully removed.");
        } else {
            log:printInfo("Failed to remove appoitment with appointment number " + appointmentId);
            util:sendResponse(caller, "Failed to remove appoitment with appointment number " + appointmentId, 
                                            statusCode = 400);
        }
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/payments"
    }
    resource function settlePayment(http:Caller caller, http:Request req) {
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
                daos:Payment|error payment = util:createNewPaymentEntry(paymentSettlement, untaint self.healthcareDao);
                if(payment is daos:Payment) {
                    payment["status"] = "Settled";
                    self.healthcareDao["payments"][<string>payment["paymentID"]] = payment;
                    util:sendResponse(caller, "Settled payment successfully with payment ID: " 
                                                                        + <string>payment["paymentID"]);
                } else {
                    log:printError("User error Invalid payload recieved, payload: ", err = payment);
                    util:sendResponse(caller, "Invalid payload recieved, " + payment.reason(), statusCode = 400);
                }
            } else {
                log:printError("Could not Find the Requested appointment ID: " 
                                    + <int>paymentSettlementDetails["appointmentNumber"]);
                util:sendResponse(caller, "Error. Could not Find the Requested appointment ID.", statusCode = 400);
            }
        } else {
            util:sendResponse(caller, "Invalid payload received", statusCode = 400);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/payments/payment/{paymentId}"
    }
    resource function getPaymentDetails(http:Caller caller, http:Request req, string paymentId) {
        var payment = self.healthcareDao["payments"][paymentId];
        if (payment is daos:Payment) {
            json|error payload = json.convert(payment);
            if (payload is json) {
                util:sendResponse(caller, payload);
            } else {
                log:printError("Error occurred getPaymentDetails when converting Payment to JSON.", err = payload);
                util:sendResponse(caller, "Intrenal error occurred.", statusCode = http:INTERNAL_SERVER_ERROR_500);
            }
        } else {
            log:printInfo("User error in getPaymentDetails, Invalid payment id provided: " + paymentId);
            util:sendResponse(caller, "Invalid payment id provided", statusCode = 400);
        }
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/admin/newdoctor"
    }
    resource function addNewDoctor(http:Caller caller, http:Request req) {
        var doctorDetails = req.getJsonPayload();
        if (doctorDetails is json) {
            string category = <string>doctorDetails["category"];
            //if category is not in the list, adding it to the list
            if (!util:containsStringElement(<string[]>self.healthcareDao["categories"], category)) {
                string[] a = <string[]>self.healthcareDao["categories"];
                a[a.length()] = category;
                self.healthcareDao["categories"] = a;
            }

            var doctor = daos:findDoctorByNameFromHelathcareDao(untaint self.healthcareDao, 
                                                                        <string>doctorDetails["name"]);
            //Adding the new doctor
            if (doctor is daos:Doctor) {
                log:printInfo("User error in addNewDoctor: Doctor Already Exists in the system.");
                util:sendResponse(caller, "Doctor Already Exist in the system", statusCode = 400);
            } else {
                daos:Doctor doc = {
                    name: <string>doctorDetails["name"],
                    hospital: <string>doctorDetails["hospital"],
                    category: <string>doctorDetails["category"],
                    availability: <string>doctorDetails["availability"],
                    fee: <float>doctorDetails["fee"]
                };
                self.healthcareDao["doctorsList"][<int>self.healthcareDao["doctorsList"].length()] = doc;
                util:sendResponse(caller, "New Doctor Added Successfully");
            }
        } else {
            util:sendResponse(caller, "Invalid payload received", statusCode = 400);
        }
    }
}
