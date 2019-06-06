import daos;
import ballerina/io;
import ballerina/log;

@http:ServiceConfig {
    basePath: "/grandoaks/categories"
}
service GrandOakHospitalService on httpListener {

    daos:Doctor doctor1 = {
        name: "thomas collins",
        hospital: "grand oak community hospital",
        category: "surgery",
        availability: "9.00 a.m - 11.00 a.m",
        fee: 7000
    };

    daos:Doctor doctor2 = {
        name: "henry parker",
        hospital: "grand oak community hospital",
        category: "ent",
        availability: "9.00 a.m - 11.00 a.m",
        fee: 4500
    };

    daos:Doctor doctor3 = {
        name: "abner jones",
        hospital: "grand oak community hospital",
        category: "gynaecology",
        availability: "8.00 a.m - 10.00 a.m",
        fee: 11000
    };

    daos:Doctor doctor4 = {
        name: "abner jones",
        hospital: "grand oak community hospital",
        category: "ent",
        availability: "8.00 a.m - 10.00 a.m",
        fee: 6750
    };

    daos:HospitalDAO clemencyHospitalDao = {
        doctorsList: [doctor1, doctor2, doctor3, doctor4],
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









