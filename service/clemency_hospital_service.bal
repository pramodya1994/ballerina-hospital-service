import daos;
import ballerina/io;
import ballerina/log;

@http:ServiceConfig {
    basePath: "/clemency/categories"
}
service ClemencyHospitalService on httpListener {

    daos:Doctor doctor1 = {
        name: "anne clement",
        hospital: "clemency medical center",
        category: "surgery",
        availability: "8.00 a.m - 10.00 a.m",
        fee: 12000
    };

    daos:Doctor doctor2 = {
        name: "thomas kirk",
        hospital: "clemency medical center",
        category: "gynaecology",
        availability: "9.00 a.m - 11.00 a.m",
        fee: 8000
    };

    daos:Doctor doctor3 = {
        name: "cailen cooper",
        hospital: "clemency medical center",
        category: "paediatric",
        availability: "9.00 a.m - 11.00 a.m",
        fee: 5500
    };

    daos:HospitalDAO clemencyHospitalDao = {
        doctorsList: [doctor1, doctor2, doctor3],
        categories: ["surgery", "cardiology", "gynaecology", "ent", "paediatric"],
        patientMap: {

        },
        patientRecordMap: {

        }
    };

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/{category}/reserve"
    }
    resource function reserveAppointment(http:Caller caller, http:Request req, string category) {
        reserveAppointment(caller, req, untaint self.clemencyHospitalDao, category);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments/{appointmentId}"
    }
    resource function getAppointment(http:Caller caller, http:Request req, int appointmentId) {
        getAppointment(caller, req, appointmentId);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/appointments/{appointmentId}/fee"
    }
    resource function checkChannellingFee(http:Caller caller, http:Request req, int appointmentId) {
        checkChannellingFee(caller, req, appointmentId);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/patient/updaterecord"
    }
    resource function updatePatientRecord(http:Caller caller, http:Request req) {
        updatePatientRecord(caller, req, self.clemencyHospitalDao);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/patient/{ssn}/getrecord"
    }
    resource function getPatientRecord(http:Caller caller, http:Request req, string ssn) {
        getPatientRecord(caller, req, self.clemencyHospitalDao, ssn);
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/patient/appointment/{appointmentId}/discount"
    }
    resource function isEligibleForDiscount(http:Caller caller, http:Request req, int appointmentId) {
        isEligibleForDiscount(caller, req, appointmentId);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/admin/doctor/newdoctor"
    }
    resource function addNewDoctor(http:Caller caller, http:Request req) {
        addNewDoctor(caller, req, untaint self.clemencyHospitalDao);
    }
}









