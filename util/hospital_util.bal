import daos;
import ballerina/log;

int appointmentNo = 1;

public function makeNewAppointment(daos:AppointmentRequest appointmentRequest, daos:HospitalDAO hospitalDao) returns daos:Appointment | daos:NotFoundError {
    var doc = daos:findDoctorByName(hospitalDao, appointmentRequest.doctor);
    if (doc is daos:NotFoundError) {
        return doc;
    } else {
        daos:Appointment appointment = {
            appointmentNumber: appointmentNo,
            doctor: doc,
            patient: appointmentRequest.patient,
            fee: doc.fee,
            confirmed: false
            // appointmentDate: appointmentRequest.appointmentDate,
            // time: "",
            // hospital: "",
            // paymentID: ""
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



