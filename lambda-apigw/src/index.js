exports.handler = async (event) => {
  console.log("event:", JSON.stringify(event, null, 2));

  const method = event.requestContext.http.method;
  const path   = event.requestContext.http.path;

  if (method === "GET" && path === "/items") {
    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ items: [{ id: 1, name: "sample" }] }),
    };
  }

  if (method === "POST" && path === "/items") {
    const body = JSON.parse(event.body ?? "{}");
    return {
      statusCode: 201,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ created: body }),
    };
  }

  return {
    statusCode: 404,
    body: JSON.stringify({ message: "Not Found" }),
  };
};
