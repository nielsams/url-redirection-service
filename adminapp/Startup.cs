using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Authorization;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using RedirectAdmin.Data;
using RedirectAdmin.Models;
using Toolbelt.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.Identity.Web;
using Microsoft.Identity.Web.UI;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.Extensions.Logging;

namespace RedirectAdmin
{
    public class Startup
    {
        private ILogger _logger;

        public Startup(IConfiguration configuration, ILogger logger)
        {
            Configuration = configuration;
            _logger = logger;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        // For more information on how to configure your application, visit https://go.microsoft.com/fwlink/?LinkID=398940
        public void ConfigureServices(IServiceCollection services)
        {
            // We need to add this to make sure the redirectURI is built with the ForwardedHeaders from Front Door
            services.Configure<ForwardedHeadersOptions>(options =>
            {
                options.ForwardedHeaders =
                    ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
                options.KnownNetworks.Clear();
                options.KnownProxies.Clear();
            });

            services.AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
              .AddMicrosoftIdentityWebApp(Configuration);

            


            services.AddControllersWithViews(options =>
            {
                var policy = new AuthorizationPolicyBuilder()
                        .RequireAuthenticatedUser()
                        .Build();
                options.Filters.Add(new AuthorizeFilter(policy));
            }).AddMicrosoftIdentityUI();

            var config = new TableConfigOptions();
            Configuration.Bind("RedirectTable", config);
            services.AddSingleton(config);

            services.AddRazorPages();
            services.AddServerSideBlazor();
            services.AddSingleton<RedirectDataTable>();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                app.UseCssLiveReload();
            }
            else
            {
                app.UseExceptionHandler("/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }

            app.UseForwardedHeaders();

            app.Use(async (context, next) =>
            {
                // Request method, scheme, and path
                _logger.LogDebug("Request Method: {Method}", context.Request.Method);
                _logger.LogDebug("Request Scheme: {Scheme}", context.Request.Scheme);
                _logger.LogDebug("Request Path: {Path}", context.Request.Path);

                // Headers
                foreach (var header in context.Request.Headers)
                {
                    _logger.LogDebug("Header: {Key}: {Value}", header.Key, header.Value);
                }

                // Connection: RemoteIp
                _logger.LogDebug("Request RemoteIp: {RemoteIpAddress}",
                    context.Connection.RemoteIpAddress);

                await next();
            });

            app.UseHttpsRedirection();
            app.UseStaticFiles();

            app.UseRouting();

            app.UseAuthentication();
            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
                endpoints.MapBlazorHub();
                endpoints.MapFallbackToPage("/_Host");
            });
        }
    }
}
