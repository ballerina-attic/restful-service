package guide.restful_service;

import ballerina.net.http;

@Description {value:"RESTful service."}
@http:configuration {basePath:"/ordermgt"}
service<http> OrderMgtService {

    // Order management is done using an in memory orders map.
    map ordersMap = {};

    @Description {value:"Resource that handles the HTTP GET requests that are directed to a specific order using path '/orders/<orderID>'"}
    @http:resourceConfig {
        methods:["GET"],
        path:"/order/{orderId}"
    }
    resource findOrder (http:Connection conn, http:InRequest req, string orderId) {
        // Find the requested order from the map and retrieve it in JSON format.
        var payload, _ = (json)ordersMap[orderId];

        // Initialize the http response message
        http:OutResponse response = {};
        // Set the JSON payload to the outgoing response message to the client.
        response.setJsonPayload(payload);

        // Send response to the client
        _ = conn.respond(response);
    }

    @Description {value:"Resource that handles the HTTP POST requests that are directed to the path '/orders' to create a new Order."}
    @http:resourceConfig {
        methods:["POST"],
        path:"/order"
    }
    resource addOrder (http:Connection conn, http:InRequest req) {
        // Initialize the HTTP response message
        http:OutResponse response = {};
        // Extract the order details from the request payload
        json orderReq = req.getJsonPayload();
        var orderId, payloadDataError = (string)orderReq.Order.ID;

        if (payloadDataError != null) {
            // Send the bad request error if the request payload is malformed
            response.setStringPayload("Error : Please check the input json payload");
            // Set 400 Bad request status code in the response message
            response.statusCode = 400;
            _ = conn.respond(response);
            return;
        }

        // Add the order to the map
        ordersMap[orderId] = orderReq;

        // Create response message
        json payload = {status:"Order Created.", orderId:orderId};
        response.setJsonPayload(payload);

        // Set 201 Created status code in the response message
        response.statusCode = 201;
        // Set 'Location' header in the response message. This can be used by the client to locate the newly added order.
        response.setHeader("Location", "http://localhost:9090/ordermgt/order/" + orderId);

        // Send response to the client
        _ = conn.respond(response);
    }

    @Description {value:"Resource that handles the HTTP PUT requests that are directed to the path '/orders' to update an existing Order."}
    @http:resourceConfig {
        methods:["PUT"],
        path:"/order/{orderId}"
    }
    resource updateOrder (http:Connection conn, http:InRequest req, string orderId) {
        // Extract the update order details from the request payload
        json updatedOrder = req.getJsonPayload();
        // Find the order that needs to be updated from the map and retrieve it in JSON format.
        var existingOrder, _ = (json)ordersMap[orderId];

        // Updating existing order with the attributes of the updated order
        if (existingOrder != null) {
            existingOrder.Order.Name = updatedOrder.Order.Name;
            existingOrder.Order.Description = updatedOrder.Order.Description;
            ordersMap[orderId] = existingOrder;
        }

        http:OutResponse response = {};
        // Set the JSON payload to the outgoing response message to the client.
        response.setJsonPayload(existingOrder);

        // Send response to the client
        _ = conn.respond(response);
    }

    @Description {value:"Resource that handles the HTTP DELETE requests that are directed to the path '/orders/<orderId>' to delete an existing Order."}
    @http:resourceConfig {
        methods:["DELETE"],
        path:"/order/{orderId}"
    }
    resource cancelOrder (http:Connection conn, http:InRequest req, string orderId) {
        http:OutResponse response = {};
        // Remove the requested order from the map.
        ordersMap.remove(orderId);

        json payload = "Order : " + orderId + " removed.";
        // Set a generated payload with order status.
        response.setJsonPayload(payload);

        // Send response to the client
        _ = conn.respond(response);
    }

}
