import { Injectable, OnApplicationBootstrap, Logger } from '@nestjs/common';
import { Customer } from './interfaces/customer.interface';
import { UrlDiscoveryService } from './services/url-discovery/url-discovery.service';
import { RegistrationService } from './services/registration/registration.service';

@Injectable()
export class AppService implements OnApplicationBootstrap {
  private readonly logger = new Logger(AppService.name);

  private baseUrl: string;
  private customer: Customer;

  constructor(
    private readonly urlDiscoveryService: UrlDiscoveryService,
    private readonly registrationService: RegistrationService,
  ) {}

  setBaseUrl(url: string) {
    this.baseUrl = url;
  }

  getBaseUrl() {
    return this.baseUrl;
  }

  async onApplicationBootstrap(): Promise<any> {
    try {
      this.setBaseUrl(await this.urlDiscoveryService.getConnectorUrl());
      this.registrationService.setUrlToRegister(this.baseUrl);
      const response$ = await this.registrationService.register();
      response$.subscribe((response) => {
        this.logger.log('=== Connector Registration Response ===');
        this.logger.log(`statusCode: ${response.status}`);
        this.logger.log(response.data);
      });
    } catch (error) {
      this.logger.log(error);
    }
  }

  setCustomer(customer: Customer): void {
    this.customer = customer;
  }

  getTransactions(
    object: string | string[] | undefined,
    object_id: string | string[] | undefined,
  ): string {
    // let html = '<h2>Last Three Transactions for ' + this.customer.id + ':</h2>';
    let html = '';
    if (object != undefined && object_id != undefined) {
      html +=
        '<h2>Last Three Transactions for ' +
        object +
        ' ' +
        object_id +
        ':</h2>';
    } else {
      html += '<h2>Last Three Transactions for:</h2>';
    }
    html += '<table style="width:100%">';
    html += '<tr><th>Date</th><th>Description</th><th>Amount</th></tr>';
    html +=
      '<tr><th>' +
      Date().toLocaleLowerCase('en-US') +
      '</th><th>Nespresso</th><th>$25.88</th></tr>';
    html +=
      '<tr><th>' +
      Date().toLocaleLowerCase('en-US') +
      '</th><th>Ralphs</th><th>$101.22</th></tr>';
    html +=
      '<tr><th>' +
      Date().toLocaleLowerCase('en-US') +
      '</th><th>Best Buy</th><th>$722.22</th></tr>';
    html += '</table>';
    return html;
  }

  getForm(): string {
    const target = this.baseUrl + '/form';
    let html = '<h2>Sample Form</h2>';
    html += `<form method="POST" action="${target}">`;
    html += '<label for="name">Name:</label>';
    html += '<input type="text" id="name" name="name" value="John Smith">';
    html += '<br>';
    html += '<label for="email">Email:</label>';
    html += '<input type="text" id="email" name="email" value="">';
    return html;
  }
}
