/* eslint-disable vars-on-top */
/* eslint-disable no-console */
import { LightningElement, wire, track } from 'lwc';
import getOrgLimits from '@salesforce/apex/LimitsMonitor_Controller.getOrgLimits';
import D3JS from '@salesforce/resourceUrl/D3JS';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';

const columns = [
    { label: 'Label', fieldName: 'label' },
    { label: 'Remaining / Max', fieldName: 'indication' },
    { label: '%', fieldName: 'score' , type:'percent', initialWidth: '50'}
];

export default class OrgLimits extends LightningElement {
    svgWidth = 250;
    svgHeight = 250;
    svgWidthSmall = 150;
    svgHeightSmall = 150;

    d3Initialized = false;

    @track ifDataRetrieved = false;
    @track allLimits = {
        dailyApiLimit:{},
        dailyBulkApiLimit:{},
        storageLimit:{},
        fileStorageLimit:{}
    };
    @track streamingData;
    @track columns = columns;


    @track activeSections = ['C', 'D'];
    @track activeSectionsMessage = '';

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        if (openSections.length === 0) {
            this.activeSectionsMessage = 'All sections are closed';
        } else {
            this.activeSectionsMessage =
                'Open sections: ' + openSections.join(', ');
        }
    }

    handleApexData() {
        getOrgLimits()
            .then(result => {
                this.allLimits = Object.assign({}, result);
                this.ifDataRetrieved = true;
                this.initializeD3(this.allLimits.analyticsLimits, 'analytics');
                this.initializeD3(this.allLimits.streamingLimits, 'streaming');
                var propertyOdd = {
                    circleColor : "#FF7777",
                    textColor : "#FF4444",
                    waveTextColor: "#FFAAAA",
                    waveColor : "#FFDDDD"
                }
                var propertyEven = {
                    circleColor : "#6DA398",
                    textColor : "#0E5144",
                    waveTextColor: "#6DA398",
                    waveColor : "#246D5F"
                }

                console.log(this.allLimits.fileStorageLimit);

                this.initializeD3Gauge(this.allLimits.dailyBulkApiLimit.score, 'apiSvg', propertyOdd);
                this.initializeD3Gauge(this.allLimits.dailyApiLimit.score, 'bulkApiSvg', propertyEven);
                this.initializeD3Gauge(this.allLimits.storageLimit.score, 'storageSvg', propertyOdd);
                this.initializeD3Gauge(this.allLimits.fileStorageLimit.score, 'flStorageSvg', propertyEven);
            })
            .catch(error => {
                this.error = error;
                console.log(error);
            });
    }
   
    renderedCallback() {
        if (this.d3Initialized) {
            return;
        }
        this.d3Initialized = true;

        Promise.all([
            loadStyle(this, D3JS + '/d3/styles.css'),
            loadScript(this, D3JS + '/d3/d3.min.js')
            .then( () => {
                loadScript(this, D3JS + '/d3/d3.tip.v0.6.3.js');
                loadScript(this, D3JS + '/d3/liquidFillGauge.js');
            })
            
        ])
        .then(() => {
            this.handleApexData();
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading D3',
                    message: error.message,
                    variant: 'error',
                }),
            );
        });
    }

    getColor(order){
        var color = "#000000";
        switch(Math.round(order)){
            case 10:
                color = "#9E0041";
                break;
            case 1:
                color = "#C32F4B";
                break;
            case 2:
                color = "#E1514B";
                break;
            case 3:
                color = "#F47245";
                break;
            case 4:
                color = "#FB9F59";
                break;
            case 5:
                color = "#FEC574";
                break;
            case 6:
                color = "#FAE38C";
                break;
            case 7:
                color = "#EAF195";
                break;
            case 8:
                color = "#C7E89E";
                break;
            case 9:
                color = "#9CD6A4";
                break;
            case 11:
                color = "#6CC4A4";
                break
            case 12:
                color = "#4D9DB4";
                break;
            case 13:
                color = "#4776B4";
                break;
            case 14:
                color = "#5E4EA1";
                break;
            default:
                color = "#5E4EA1";
                break;
        }
        return color;
    }

    initializeD3(limitData, svgClass) {
        // Example adopted from https://bl.ocks.org/mbostock/2675ff61ea5e063ede2b5d63c08020c7
        
        console.log(limitData);
        var data = JSON.parse(JSON.stringify(limitData));
        const width = this.svgWidth;
        const height = this.svgHeight;
        const radius = Math.min(width, height)/2;
        const innerRadius = 0.3 * radius;
        //const color = d3.scaleOrdinal(d3.schemeDark2);

        const pie = d3.pie()
                    .sort(null)
                    .value(function(d) {return d.width});
 
        var tip = d3.tip()
                .attr('class', 'd3-tip')
                .offset([-8, 0])
                .html(function(d) {
                    return d.data.label + ": " + Math.round(d.data.score) + "%" ;
                });

        var arc = d3.arc()
                    .innerRadius(innerRadius)
                    .outerRadius(function (d) { 
                      return (radius - innerRadius) * (d.data.score / 100.0) + innerRadius; 
                    });
          
        var outlineArc = d3.arc()
                    .innerRadius(innerRadius)
                    .outerRadius(radius);
          
        const svg =   d3.select(this.template.querySelector('svg.'+svgClass))
                      .attr("width", width)
                      .attr("height", height)
                      .append("g")
                      .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");
          
        svg.call(tip);
       
        data.forEach(function(d, index) {
            d.id     =  d.name;
            d.order  = +d.order;
            console.log(this);
            d.color  =  this.getColor(d.order);
            d.weight = +d.weight;
            d.score  = +(d.score * 100);
            console.log(d.score);
            d.width  = +d.weight;
        }, this);
                    
        console.log(svg);

        var path = svg.selectAll(".solidArc")
            .data(pie(data))
            .enter().append("path")
            .attr("fill", function(d) { return d.data.color; })
            .attr("class", "solidArc")
            .attr("stroke", "gray")
            .attr("d", arc)
            .on('mouseover', tip.show)
            .on('mouseout', tip.hide);

        var outerPath = svg.selectAll(".outlineArc")
            .data(pie(data))
            .enter().append("path")
            .attr("fill", "none")
            .attr("stroke", "gray")
            .attr("class", "outlineArc")
            .attr("d", outlineArc)  
          
        // calculate the weighted mean score
        var score = 
            data.reduce(function(a, b) {
            return a + (b.score * b.weight); 
            }, 0) / 
            data.reduce(function(a, b) { 
            return a + b.weight; 
            }, 0);

    }

    initializeD3Gauge(percent, svgClass, properties){
        console.log('D3 Gauge');
        d3.select(this.template.querySelector('svg.'+svgClass)).call(d3.liquidfillgauge, percent*100, {
            circleColor: properties.circleColor,
            textColor: properties.textColor,
            waveTextColor: properties.waveTextColor,
            waveColor: properties.waveColor,
            circleThickness: 0.1,
            textVertPosition: 0.2,
            waveAnimateTime: 1000,
            backgroundColor: "#e0e0e0",
            valueCountUpAtStart: false,
            waveRiseAtStart: false
            });
    }
}