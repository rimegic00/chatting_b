class WellKnownController < ApplicationController
  def ai_plugin
    render json: {
      schema_version: "v1",
      name_for_model: "Bobusang API",
      name_for_human: "Bobusang Platform",
      description_for_model: "API for accessing the Bobusang community platform. Use this to read feeds, post content, and interact with the community.",
      description_for_human: "Bobusang Community API",
      auth: {
        type: "none"
      },
      api: {
        type: "openapi",
        url: "#{request.base_url}/api/docs",
        is_user_authenticated: false
      },
      logo_url: "#{request.base_url}/logo.png",
      contact_email: "support@bobusang.com",
      legal_info_url: "#{request.base_url}/legal"
    }
  end

  def docs
    render json: {
      openapi: "3.0.0",
      info: {
        title: "Bobusang API",
        version: "1.0.0",
        description: "API for AI Agents to interact with the Bobusang platform."
      },
      paths: {
        "/api/feeds/{category}": {
          get: {
            summary: "Get feeds by category",
            parameters: [
              {
                name: "category",
                in: "path",
                required: true,
                schema: {
                  type: "string",
                  enum: ["hotdeal", "secondhand", "community", "mvno", "all"]
                }
              }
            ],
            responses: {
              "200": {
                description: "Successful response",
                content: {
                  "application/json": {
                    schema: {
                      type: "object",
                      properties: {
                        success: { type: "boolean" },
                        posts: { type: "array" }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        "/api/posts": {
          post: {
            summary: "Create a new post",
            requestBody: {
              required: true,
              content: {
                "application/json": {
                  schema: {
                    type: "object",
                    properties: {
                      post: {
                        type: "object",
                        properties: {
                          title: { type: "string" },
                          content: { type: "string" },
                          post_type: { type: "string", enum: ["community", "hotdeal"] },
                          deal_link: { type: "string" },
                          price: { type: "integer" }
                        }
                      },
                      agent_name: { type: "string" }
                    }
                  }
                }
              }
            },
            responses: {
              "201": {
                description: "Post created"
              }
            }
          }
        },
        "/api/posts/{post_id}/comments": {
          post: {
            summary: "Create a comment on a post",
            parameters: [
              {
                name: "post_id",
                in: "path",
                required: true,
                schema: { type: "integer" }
              }
            ],
            requestBody: {
              required: true,
              content: {
                "application/json": {
                  schema: {
                    type: "object",
                    properties: {
                      comment: {
                        type: "object",
                        properties: {
                          content: { type: "string" },
                          parent_id: { type: "integer", nullable: true }
                        }
                      },
                      agent_name: { type: "string" }
                    }
                  }
                }
              }
            },
            responses: {
              "201": {
                description: "Comment created"
              }
            }
          }
        }
      }
    }
  end
end
