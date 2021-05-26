import { Component } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { debounceTime, map } from 'rxjs/operators';
import { ISinistralidade,IChart } from './app.interface';
import { PoGaugeRanges } from '@po-ui/ng-components';


@Component({
  selector: 'app-root',
  templateUrl: './app.component.html'
})
export class AppComponent {
  company: Observable<any>;
  companyCode: string;
  companyName: string;
  showInfo=false;
  values:any[];
  valueChart=[];
  totalValue:number;
  agreedValue:number;
  percentual:number;
  ranges: Array<PoGaugeRanges> 

  constructor(private http: HttpClient) {}  

  onChangeCompany(companyCode: string) {
    if (companyCode != undefined){
      this.showInfo=false;
      this.totalValue = 0;
      this.agreedValue = 0;
      this.getCompany(companyCode).pipe(debounceTime(400))
      .subscribe({
        complete: () => { this.showInfo= true; },
        next: (data) => {        
          this.values =  data.values;
          this.totalValue =  data.totalValue;
          this.agreedValue =  data.agreedValue;
          this.percentual = Math.floor((this.totalValue*100)/this.agreedValue * 100) / 100
          this.ranges= [
            { from: 0, to: this.agreedValue/3, label: 'Baixo', color: '#00b28e' },
            { from: this.agreedValue/3, to: this.agreedValue/2, label: 'Médio', color: '#ea9b3e' },
            { from: this.agreedValue/2, to: this.agreedValue, label: 'Alto', color: '#c64840' }
          ];
          let array = {} as IChart;
          this.valueChart=[];
          for(let i=0; i < this.values.length; i++){
            array = {} as IChart;
            array.label = this.values[i].description;
            array.data = this.values[i].value ;
            this.valueChart.push(array);          
          }
          
          
        },
      });    
    }
  }

  private getCompany(companyCode: string) {
    
    return this.http.get(`http://10.171.67.162:8011/rest/convenio/v1/lossRatio?company=${companyCode}`).pipe(
      debounceTime(400),
      map((data) => {
        return {   
          totalValue:       data['totalValue'] as  number,       
          agreedValue:      data['agreedValue'] as number,       
          values: data['items'].map((info) => {
            return {
              description: info.description,
              value:  info.value,             
            };
          }) as ISinistralidade[],
        };
      }),      
    );
  }
}