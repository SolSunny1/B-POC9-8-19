global with sharing class Common_QueryBuilder {
    public static final String className = 'Common_QueryBuilder';
	public Set<String> queryFields;
	public List<Common_QueryBuilder> innerQueries;
	public String objectAPIName;
    Schema.SObjectType typeToQuery;
    Boolean selectAllFields = false;
    Boolean includeSystemFields = true;

	public LogicalGrouping whereFilter;
	public String whereClause;

	public List<String> orderbyFields;

	public List<String> groupbyFields;
	public Integer rowLimit;
	public Integer offSet;

	global Common_QueryBuilder(String objectName){
		objectAPIName = objectName;
		queryFields = new Set<String>();
		groupbyFields = new List<String>();
		orderbyFields = new List<String>();
		whereFilter = new LogicalGrouping('AND');
		innerQueries = new List<Common_QueryBuilder>();
	}

	global void clearQueryFields(){
		queryFields = new Set<String>();
		innerQueries = new List<Common_QueryBuilder>();
	}

	global void addQueryField(String field){
		queryFields.add(field);
	}

	global void addQueryFields(List<String> fields){
		queryFields.addAll(fields);
	}

	global void addInnerQuery(Common_QueryBuilder innerQuerie){
		innerQueries.add(innerQuerie);
	}

	global override String toString(){
		String query = 'SELECT ';
		List<String> fullFieldList = new List<String>();
		if(!queryFields.isEmpty()){
			fullFieldList.addAll(queryFields);
		} else {
			fullFieldList.add('ID');
		}

		if(!innerQueries.isEmpty()){
			for(Common_QueryBuilder qb:innerQueries){
				fullFieldList.add('('+qb.toString()+')');
			}
		}
		query += String.join(fullFieldList,',');

		system.debug('objectAPIName = ' + objectAPIName);
		query+= ' FROM '+objectAPIName;

		String builtWhereClause = '';
		if(!String.isBlank(whereClause)){
			builtWhereClause += ' WHERE ('+ whereClause +')';
		}
		if(whereFilter!= null){
		system.debug('whereFilter = ' + whereFilter);
			String compiledFilters = whereFilter.toString();
		system.debug('compiledFilters = ' + compiledFilters);
			if(!String.isBlank(compiledFilters)){
				if(String.isBlank(builtWhereClause)){
					builtWhereClause += ' WHERE '+whereFilter.toString();
				} else {
					Boolean isOperatorMismatch = !whereFilter.logicalOperator.equalsIgnoreCase('AND');
					builtWhereClause += ' AND ';
					if(isOperatorMismatch){
						builtWhereClause += '(';
					}
					builtWhereClause += whereFilter.toString();
					if(isOperatorMismatch){
						builtWhereClause += ')';
					}
				}
			}
			system.debug('builtWhereClause: ' + builtWhereClause);
		}
		query += builtWhereClause;

		if(!groupbyFields.isEmpty()){
			query += ' GROUP BY '+String.join(groupbyFields,',');
		}

		if(!orderbyFields.isEmpty()){
			query += ' ORDER BY '+String.join(orderbyFields,',');
		}

		if(rowLimit != null){
			query += ' LIMIT '+String.valueOf(rowLimit);
		}

		if(offSet != null){
			query += ' OFFSET '+String.valueOf(offSet);
		}

		System.debug(query);
		return query;
	}

	global void clearWhereFilter(){
		whereFilter = new LogicalGrouping('AND');
		whereClause = null;
	}

	/**
	 * Deprecated.  Instead use extendWhereFilter.
	 */
	global void addWhereFilter(String formattedFilter){
		whereClause = '('+formattedFilter+')';
	}

	global void extendWhereFilter(String formattedFilter){
		if(whereClause != null){
			whereClause += ' AND ('+formattedFilter+')';
		} else {
			addWhereFilter(formattedFilter);
		}
	}

	global void extendWhereFilter(String formattedFilter, String logicalOperator){
		if(whereClause != null){
			whereClause += ' '+logicalOperator+' ('+formattedFilter+')';
		} else {
			addWhereFilter(formattedFilter);
		}
	}

	global void addWhereFilter(String fieldName, Object value, String operator){
		whereFilter.filterElements.add(new FilterElement(fieldName, new List<Object>{value}, operator));
	}

	global void addWhereFilter(String fieldName, List<Object> values){
		addWhereFilter(fieldName, values, 'IN');
	}

	global void addWhereFilter(String fieldName, List<Object> values, String operator){
		whereFilter.filterElements.add(new FilterElement(fieldName, values, operator));
	}

	global void addWhereFilterSeries(LogicalGrouping filterGroup){
		whereFilter.subgroupings.add(filterGroup);
	}

	global void addWhereFilterSeries(List<String> fieldNames, List<List<Object>> filterValues, List<String>compairsonOperators, List<String> logicalOperators){
		Set<String> logicalOpSet = new Set<String>(logicalOperators);
		//This is an optimization, skip the complex logic if we don't need it
		if(logicalOpSet.contains('OR')){
			Integer nextLogicalOpPosition = 0;
			String lastLogicalOp;

			LogicalGrouping lg;

			for(Integer i=0;i<fieldNames.size();i++){
				String fieldName = fieldNames[i];
				List<Object> filterList = filterValues[i];
				String compairsonOp = compairsonOperators[i];

				String nextLogicalOp = logicalOperators[nextLogicalOpPosition].toUpperCase();
				nextLogicalOpPosition++;

				if(nextLogicalOp.equalsIgnoreCase('OR')){
					if(lg == null){
						lg = new LogicalGrouping('OR');
					}
					lg.filterElements.add(new FilterElement(fieldName,filterList, compairsonOp));
					//read ahead, should we store now?
					if(nextLogicalOpPosition>=logicalOperators.size() || logicalOperators[nextLogicalOpPosition].toUpperCase() != nextLogicalOp){
						whereFilter.subgroupings.add(lg);
						lg = null;
					}
				} else {
					addWhereFilter(fieldName,filterList,compairsonOp);
				}
			}

		} else {
			for(Integer i=0;i<fieldNames.size();i++){
				addWhereFilter(fieldNames[i],filterValues[i],compairsonOperators[i]);
			}
		}
	}

	global void setWhereFilterPrimaryOperator(String operator){
		whereFilter.logicalOperator = operator;
	}

	global void clearOrderFields(){
		orderbyFields = new List<String>();
	}

	global void addOrderField(String field){
		addOrderField(field, null, null);
	}

	global void addOrderField(String field, String direction){
		addOrderField(field, direction, null);
	}

	global void addOrderField(String field, String direction, String nullPosition){
		String orderEntry = field;
		if(!String.isBlank(direction)){
			orderEntry += ' '+direction;
		}
		if(!String.isBlank(nullPosition)){
			orderEntry += ' '+nullPosition;
		}

		Set<String> checkForDupes = new Set<String>(orderbyFields);
		if(!checkForDupes.contains(orderEntry)){
			orderbyFields.add(orderEntry);
		}
	}

	global void setRowLimit(Integer maxRows){
		if(maxRows == null || maxRows<1){
			rowLimit = null;
		} else {
			rowLimit = maxRows;
		}
	}

	global void setOffset(Integer rowOffset){
		if(rowOffset == null || rowOffset<1){
			offSet = null;
		} else {
			offSet = rowOffset;
		}
	}

	global void addGroupField(String field){
		groupbyFields.add(field);
	}
    
    public void EnableSelectAllLocalFields(Boolean includeSystemFields){
        selectAllFields = true;
        this.includeSystemFields = includeSystemFields;
    }
    
    public static String BuildAllFieldsQuery(Schema.SObjectType token, String optionalWhereClause){
        return BuildQueryHelper(token, true, null, null, optionalWhereClause);
    }

    public static String BuildAllFieldsQuery(String sobjectType, Boolean includeSystemFields, String optionalWhereClause){
        Schema.SObjectType token = Schema.getGlobalDescribe().get(sobjectType);
        return BuildQueryHelper(token, includeSystemFields, null, null, optionalWhereClause);
    }
    
    private static String BuildQueryHelper(Schema.SObjectType token, Boolean includeSystemFields, List<String> fieldsToQuery, List<String> crossTableFields, String optionalWhereClause){
        //build select clause
        String objectFields = fieldsToQuery==null ? ' ' + Common_Query.GetAllFields(token, includeSystemFields) + ' ' : ' ' + String.join(fieldsToQuery, ',') + ' ';
        String crossObjectFields = crossTableFields==null ? '' : ',' + String.join(crossTableFields, ',') + ' ';
        String selectPart = ' SELECT ' + objectFields + crossObjectFields;
        
        //build where clause
        String wherePart =  optionalWhereClause==null|| String.isBlank(optionalWhereClause) ? '' : (optionalWhereClause.containsIgnoreCase('where ') ? + ' ' + optionalWhereClause : ' WHERE ' + optionalWhereClause);
        
        //build whole query    
        String query = selectPart + ' FROM ' + token.getDescribe().getName() + wherePart;
        
        return query;
    }

	global class LogicalGrouping{
		global String logicalOperator;
		global List<LogicalGrouping> subgroupings;
		global List<FilterElement> filterElements;

		global LogicalGrouping(String logicalOperator){
			this.logicalOperator = logicalOperator;
			subgroupings = new List<LogicalGrouping>();
			filterElements = new List<FilterElement>();
		}

		global LogicalGrouping(String logicalOperator, FilterElement filterEntry){
			this(logicalOperator);
			filterElements.add(filterEntry);
		}

		global override String toString(){
			if((filterElements == null || filterElements.isEmpty()) && (subgroupings == null || subgroupings.isEmpty())){
				return '';
			}

			String whereClause = '';


			if(filterElements != null && !filterElements.isEmpty()){
				List<String> filterStrings = new List<String>();
				for(FilterElement fe:filterElements){
					filterStrings.add(fe.toString());
				}
				
				whereClause += String.join(filterStrings,' '+logicalOperator+' ');
			}

			if(subgroupings != null && !subgroupings.isEmpty()){
				if(whereClause != '(' && whereClause != ''){
					whereClause += ' '+logicalOperator+' ';
				}
				List<String> subgroupStrings = new List<String>();
				for(LogicalGrouping lg:subgroupings){
					String filterString = lg.toString();
					if(lg.logicalOperator != this.logicalOperator){
						filterString = '('+filterString+')';
					}
					subgroupStrings.add(filterString);
				}
				whereClause += String.join(subgroupStrings,' '+logicalOperator+' ');
			}

			return whereClause;
		}
	}

	global class FilterElement{
		public String fieldName;
		public String operator;
		public List<Object> filterValues;
		public String precompiledFilter;

		global FilterElement(String field, List<Object> values, String operator){
			fieldName = field;
			filterValues = values;
			this.operator = operator;
		}

		global FilterElement(String precompiledFilter){
			this.precompiledFilter = precompiledFilter;
		}

		global override String toString(){
			if(fieldName == null){
				return precompiledFilter;
			} else {
				String filterString = fieldName+' '+operator+' ';

				if(filterValues != null && !filterValues.isEmpty()){
					List<String> processingValues = new List<String>();
					//Todo: look into replacing this with the logic from Common_Reflection
					String fieldType = 'string';
					if(filterValues[0] == null){
						fieldType = 'null';
					} else if(filterValues[0] instanceOf Date){
						fieldType = 'date';
					} else if(filterValues[0] instanceOf DateTime){
						fieldType = 'datetime';
					} else if(filterValues[0] instanceOf Integer){
						fieldType = 'integer';
					} else if(filterValues[0] instanceOf Decimal){
						fieldType = 'decimal';
					} else if(filterValues[0] instanceOf Double){
						fieldType = 'double';
					} else if(filterValues[0] instanceOf Boolean){
						fieldType = 'boolean';
					}

					for(Object filterValue:filterValues){
						if(fieldType == 'string'){
							processingValues.add('\''+String.escapeSingleQuotes(String.valueOf(filterValue))+'\'');
						} else if(fieldType == 'date'){
							String sValue = String.valueOf(filterValue).substringBefore('T');
							processingValues.add(sValue);
						} else if(fieldType == 'null'){
							processingValues.add(null);
						} else {
							processingValues.add(String.valueOf(filterValue));
						}
					}

					if(processingValues.size() == 1 && !operator.equalsIgnoreCase('includes') && !operator.equalsIgnoreCase('in') && !operator.equalsIgnoreCase('excludes')){
						filterString += processingValues[0];
					} else if(operator.equalsIgnoreCase('in') || operator.equalsIgnoreCase('includes') || operator.equalsIgnoreCase('excludes')){
						filterString += '(' + String.join(processingValues,',') +')';
					} else {
						filterString += String.join(processingValues,',');
					}
				} else {
					filterString += 'null';
				}

				return filterString;
			}
		}
	}
}