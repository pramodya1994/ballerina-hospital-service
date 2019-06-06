import daos;
import ballerina/http;
import ballerina/system;
import ballerina/time;
import ballerina/log;

int appointmentNo = 1;

public function sendResponse(http:Caller caller, json|string payload, int statusCode = 200) {
    http:Response response = new;
    response.setPayload(untaint payload);
    response.statusCode = statusCode;
    var result = caller->respond(response);
    if (result is error) {
        log:printError("Error sending response.", err = result);
    }
}

public function containsStringElement(string[] arr, string element) returns boolean {
    foreach var item in arr {
        if (item.equalsIgnoreCase(element)) {
            return true;
        }
    }
    return false;
}

public function containsInPatientRecordMap(map<daos:PatientRecord> patientRecordMap, string ssn) returns boolean {
    foreach (string, daos:PatientRecord) (k, v) in patientRecordMap {
        daos:Patient patient = <daos:Patient> v["patient"];
        if (<boolean>patient["ssn"].equalsIgnoreCase(ssn)) {
            return true;
        }
    }
    return false;
}

public function convertJsonToStringArray(json[] array) returns string[] {
    string[] result = [];
    foreach var item in array {
        result[result.length()] = <string>item;
    }
    return result;
}

public function createNewPaymentEntry(daos:PaymentSettlement paymentSettlement, daos:HealthcareDao healthcareDao) 
                                            returns daos:Payment | error {
    int discount = check checkForDiscounts(<string>paymentSettlement["patient"]["dob"]);
    string doctorName = <string>paymentSettlement["doctor"]["name"];
    daos:Doctor doctor = check daos:findDoctorByNameFromHelathcareDao(healthcareDao, doctorName);
    float discounted = (<float>doctor["fee"] / 100) * (100 - discount);

    daos:Payment payment = {
        appointmentNo: <int>paymentSettlement["appointmentNo"],
        doctorName: <string>paymentSettlement["doctor"]["name"],
        patient: <string>paymentSettlement["patient"]["name"],
        actualFee: <float>doctor["fee"],
        discount: discount: 0,
        discounted: discounted: 0.0,
        paymentID: system:uuid(),
        status: ""
    };
    return payment;
}

public function makeNewAppointment(daos:AppointmentRequest appointmentRequest, daos:HospitalDAO hospitalDao) 
                                            returns daos:Appointment | daos:DoctorNotFoundError {
    var doc = daos:findDoctorByName(hospitalDao, appointmentRequest.doctor);
    if (doc is daos:DoctorNotFoundError) {
        return doc;
    } else {
        daos:Appointment appointment = {
            appointmentNumber: appointmentNo,
            doctor: doc,
            patient: appointmentRequest.patient,
            fee: doc.fee,
            confirmed: false
        };
        appointmentNo = appointmentNo + 1;
        return appointment;
    }
}

# Discount is calculated by checking the age considering the birth year only.
#
# + dob - dob Parameter date of birth as a string in yyyy-MM-dd format 
# + return - Return Value discount value
public function checkForDiscounts(string dob) returns int | error {
    int yob = check int.convert(dob.split("-")[0]);
    int currentYear = time:getYear(time:currentTime());
    int age = currentYear - yob;
    if (age < 12) {
        return 15;
    } else if (age > 55) {
        return 20;
    } else {
        return 0;
    }
}

public function checkDiscountEligibility(string dob) returns boolean | error {
    var yob = int.convert(dob.split("-")[0]);
    if (yob is int) {
        int currentYear = time:getYear(time:currentTime());
        int age = currentYear - yob;

        if (age < 12 || age > 55) {
            return true;
        } else {
            return false;
        }
    } else {
        log:printError("Error occurred when converting string dob year to int.", err = ());
        return yob;
    }
}

public function containsAppointmentId(map<daos:Appointment> appointmentsMap, string id) returns boolean {
    foreach (string, daos:Appointment) (k, v) in appointmentsMap {
        if (k.equalsIgnoreCase(id)) {
            return true;
        }
    }
    return false;
}
