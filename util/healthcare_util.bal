import daos;
import ballerina/time;
import ballerina/system;

public function createNewPaymentEntry(daos:PaymentSettlement paymentSettlement, daos:HealthcareDao healthcareDao) returns daos:Payment | error {
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


